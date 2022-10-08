//
//  FileBase.swift
//  QLProvision
//
//  Created by zhouziyuan on 2022/9/21.
//

import Cocoa
import Security
import WebKit

class Preview {
    let url: URL
    let handler: (Error?) -> Void
    let dataType: DataType
    var provisionData: Data?
    var appPlist: Data?
    var entitlements: Entitlements?
    var appIcon: NSImage?
    let unZip: UnZip?
    
    lazy var currentTempDirFolder: String = Paths.TeamPath(isDeleteOld: true)
    /// 需要特殊标明的测试设备
    var specialDevices: [Device] = Device.userDevices()
    var synthesizedInfo: [String: String] = ["ProvisionInfo": "",
                                             "BundleShortVersionString": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
                                             "BundleVersion": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""]
    lazy var html: String = {
        guard let path = Bundle.main.path(forResource: "template", ofType: "html") else { return "" }
        let html = try? String(contentsOfFile: path)
        return html ?? ""
    }()

    init?(url: URL, handler: @escaping (Error?) -> Void) {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.typeIdentifierKey])
            guard let UTI = resourceValues.typeIdentifier, let dataType = DataType(rawValue: UTI) else {
                handler(Errors.Invalid)
                return nil
            }
            self.handler = handler
            self.url = url
            self.dataType = dataType
            self.unZip = dataType == .Ipa ? UnZip(url: url) : nil
            try self.unZip?.run()
        } catch {
            handler(error)
            return nil
        }
    }

    func run(web: WKWebView) {
        do {
            try readFile()
            // 读取标题
            readTitle()
            // 读取app信息
            readAppInfo()
            // 读取描述文件信息
            readProvisionInfo()
            // 读取文件大小，创建时间
            readFileInfo()
            // 将所有信息在网页上显示
            showHtml(web: web)
            handler(nil)
        } catch {
            handler(error)
        }
    }
    
    // 读取文件内部信息
    func readFile() throws {
/*
        if dataType == .App {
            let contentsURL = url.appendingPathComponent("Contents")
            guard !contentsURL.path.directoryExists else {
                throw Errors.MacOSInvalid
            }
            
        } else
*/
        if dataType == .Archive {
            let appsDir = url.appendingPathComponent("Products/Applications/")
            let dirFiles = try FileManager.default.contentsOfDirectory(atPath: appsDir.path)
            guard let path = dirFiles.first else { return }
            let appURL = appsDir.appendingPathComponent(path, isDirectory: true)
            let contentsURL = appURL / "Contents"
            if contentsURL.path.directoryExists { // macOS
                // macOS的Archive查看有问题。暂时得不到解决
                throw Errors.MacOSInvalid
/*
                provisionData = try Data(contentsOf: contentsURL.appendingPathComponent("embedded.provisionprofile"))
                appPlist = try Data(contentsOf: contentsURL.appendingPathComponent("Info.plist"))
                guard let bundleExecutable: String = appPlist?.xmlToDictionary?.value(key: "CFBundleExecutable") else { return }
                
                let binaryPath = contentsURL.path / "MacOS" / bundleExecutable
                entitlements = try EntitlementsReader(binaryPath).readEntitlements()
*/
            } else {
                provisionData = try Data(contentsOf: appURL.appendingPathComponent("embedded.mobileprovision"))
                appPlist = try Data(contentsOf: appURL.appendingPathComponent("Info.plist"))
                guard let bundleExecutable: String = appPlist?.xmlToDictionary?.value(key: "CFBundleExecutable") else { return }
                
                let binaryPath = appURL.path / bundleExecutable
                entitlements = try EntitlementsReader(binaryPath).readEntitlements()
            }
        } else if dataType == .Ipa {
            provisionData = unZip?.provisionData
            appPlist = unZip?.appPlist
            entitlements = unZip?.entitlements
        } else {
            provisionData = try Data(contentsOf: url)
        }
    }
    
    /// 读取标题
    func readTitle() {
        guard dataType == .Archive || dataType == .Ipa else { return }
        synthesizedInfo["AppInfoTitle"] = "App info"
        
        if provisionData == nil {
            synthesizedInfo["ProvisionInfo"] = "hiddenDiv"
        }
    }
    
    /// 读取app信息
    func readAppInfo() {
        guard dataType == .Ipa || dataType == .Archive else {
            synthesizedInfo["AppInfo"] = "hiddenDiv"
            synthesizedInfo["ProvisionAsSubheader"] = ""
            return
        }
        guard let appPropertyList = appPlist?.xmlToDictionary else { return }
        var bundleName = appPropertyList.value(key: "CFBundleDisplayName") ?? ""
        if bundleName.isEmpty {
            bundleName = appPropertyList.value(key: "CFBundleName") ?? ""
        }
        self.synthesizedInfo["CFBundleName"] = bundleName
        self.synthesizedInfo["CFBundleIdentifier"] = appPropertyList.value(key: "CFBundleIdentifier") ?? ""
        self.synthesizedInfo["CFBundleShortVersionString"] = appPropertyList.value(key: "CFBundleShortVersionString") ?? ""
        self.synthesizedInfo["CFBundleVersion"] = appPropertyList.value(key: "CFBundleVersion") ?? ""
        let sdkName = appPropertyList.value(key: "DTSDKName") ?? ""
        self.synthesizedInfo["DTSDKName"] = sdkName
        self.synthesizedInfo["MinimumOSVersion"] = appPropertyList.value(key: "MinimumOSVersion") ?? ""
        var appTransportSecurityFormatted = "No exceptions"
        if let appTransportSecurity: [String: Any] = appPropertyList.value(key: "NSAppTransportSecurity") {
            let localizedKeys = [
                "NSAllowsArbitraryLoads": "Allows Arbitrary Loads",
                "NSAllowsArbitraryLoadsForMedia": "Allows Arbitrary Loads for Media",
                "NSAllowsArbitraryLoadsInWebContent": "Allows Arbitrary Loads in Web Content",
                "NSAllowsLocalNetworking": "Allows Local Networking",
                "NSExceptionDomains": "Exception Domains",
                
                "NSIncludesSubdomains": "Includes Subdomains",
                "NSRequiresCertificateTransparency": "Requires Certificate Transparency",
                
                "NSExceptionAllowsInsecureHTTPLoads": "Allows Insecure HTTP Loads",
                "NSExceptionMinimumTLSVersion": "Minimum TLS Version",
                "NSExceptionRequiresForwardSecrecy": "Requires Forward Secrecy",
                
                "NSThirdPartyExceptionAllowsInsecureHTTPLoads": "Allows Insecure HTTP Loads",
                "NSThirdPartyExceptionMinimumTLSVersion": "Minimum TLS Version",
                "NSThirdPartyExceptionRequiresForwardSecrecy": "Requires Forward Secrecy"
            ]
            let formattedDictionaryString = appTransportSecurity.formatXML(replacements: localizedKeys)
            appTransportSecurityFormatted = "<div class=\"list\">\(formattedDictionaryString)</div>"
        } else if let sdkNum = Double(sdkName.trimmingCharacters(in: .letters)), sdkNum < 9 {
            appTransportSecurityFormatted = "Not applicable before iOS 9.0"
        }
        synthesizedInfo["AppTransportSecurityFormatted"] = appTransportSecurityFormatted
        func mainIconNameForApp(_ dic: [String: Any]) -> String {
            func iconsList(_ dic: [String: Any]?) -> [String]? {
                guard let primaryIconDict: [String: Any] = dic?.value(key: "CFBundlePrimaryIcon") else { return nil }
                guard let tempIcons: [String] = primaryIconDict.value(key: "CFBundleIconFiles") else { return nil }
                return tempIcons
            }
            
            var icons: [String]? = iconsList(dic.value(key: "CFBundleIcons"))
            if icons == nil {
                icons = iconsList(dic.value(key: "CFBundleIcons~ipad"))
            }
            if icons == nil, let tempIcons: [String] = dic.value(key: "CFBundleIconFiles") {
                icons = tempIcons
            }
            var iconName = ""
            if let icons = icons {
                iconName = icons.filter({ $0.contains("120") }).first ?? icons.filter({ $0.contains("60") }).first ?? icons.last ?? ""
            } else if let legacyIcon: String = dic.value(key: "CFBundleIconFile") {
                iconName = legacyIcon
            }
            return iconName
        }
        let iconName = mainIconNameForApp(appPropertyList)
        appIcon = imageForApp(iconName: iconName)
        let platformNums: [Int]? = appPropertyList.value(key: "UIDeviceFamily")
        let platforms = platformNums?.filter({ $0 == 1 || $0 == 2 }).map({ $0 == 1 ? "iPhone" : "iPad" }) ?? []
        synthesizedInfo["UIDeviceFamily"] = platforms.joined(separator: ", ")
        // 如果没有图标，就使用默认图标
        if appIcon == nil, let path = Bundle.main.path(forResource: "defaultIcon", ofType: "png") {
            appIcon = NSImage(contentsOfFile: path)
        }
        // 图标圆角
        appIcon = appIcon?.roundCorners
        var base64 = ""
        if let imageData = appIcon?.tiffRepresentation, let imageRep = NSBitmapImageRep(data: imageData) {
            base64 = imageRep.representation(using: .png, properties: [:])?.base64EncodedString() ?? ""
        }
        synthesizedInfo["AppIcon"] = base64
        synthesizedInfo["AppInfo"] = ""
        synthesizedInfo["ProvisionAsSubheader"] = "hiddenDiv"
    }
    
    /// 图标，描述文件没有图标
    func imageForApp(iconName: String) -> NSImage? {
        if dataType == .Ipa {
            if let iconData = unZip?.iconData {
                return NSImage(data: iconData)
            }
            return nil
            // let process = Process()
            // process.launchPath = CommandLine.Unzip
            // process.currentDirectoryPath = url.deletingLastPathComponent().path
            // let pipe = Pipe()
            // process.standardOutput = pipe
            // process.arguments = ["-p", url.path, "Payload/*.app/\(iconName)*"]
            // process.launch()
            //
            // let data = pipe.fileHandleForReading.readDataToEndOfFile()
            // process.waitUntilExit()
            //
            // return NSImage(data: data)
        } else if dataType == .Archive {
            let appDir = url.appendingPathComponent("Products/Applications/")
            guard appDir.path.directoryExists else { return nil }
            do {
                let dirFiles = try FileManager.default.contentsOfDirectory(atPath: appDir.path)
                guard let appName = dirFiles.first, !appName.isEmpty else { return nil }
                let appURL = appDir.appendingPathComponent(appName)
                let appContents = try FileManager.default.contentsOfDirectory(atPath: appURL.path)
                guard let appIconFullName = appContents.filter({ $0.contains(iconName) }).last else { return nil }
                let appIconFullURL = appURL.appendingPathComponent(appIconFullName)
                return NSImage(contentsOf: appIconFullURL)
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
        return nil
    }
    
    /// 读取描述文件信息
    func readProvisionInfo() {
        // 将描述文件内容解析成字典
        guard let provisionData = provisionData as? NSData else { return }
        var newDecoder: CMSDecoder?
        CMSDecoderCreate(&newDecoder)
        guard let decoder = newDecoder else { return }
        guard CMSDecoderUpdateMessage(decoder, provisionData.bytes, provisionData.length) != errSecUnknownFormat, CMSDecoderFinalizeMessage(decoder) != errSecUnknownFormat else { return }
        var newData: CFData?
        CMSDecoderCopyContent(decoder, &newData)
        guard let data = newData as? Data, let propertyList = data.xmlToDictionary else { return }
        propertyList.forEach {
            html = html.replacingOccurrences(of: "__\($0.0)__", with: "\($0.1)")
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        let calendar = Calendar.current
        var getTaskAllow = false
        var hasDevices = false
        // 证书创建时间
        if let date: Date = propertyList.value(key: "CreationDate") {
            synthesizedInfo["CreationDateFormatted"] = dateFormatter.string(from: date)
            let creationSummary: String
            if calendar.isDate(date, inSameDayAs: .now) {
                creationSummary = "今天创建"
            } else {
                let format = DateComponentsFormatter()
                format.unitsStyle = .full
                format.maximumUnitCount = 1
                let dateComponents = calendar.dateComponents(Set([.day, .hour, .minute]), from: date, to: .now)
                creationSummary = "\(format.string(from: dateComponents)?.replacingOccurrences(of: "days", with: "天前创建") ?? "？？")"
            }
            synthesizedInfo["CreationSummary"] = creationSummary
        }
        // 证书过期日间
        if let date: Date = propertyList.value(key: "ExpirationDate") {
            synthesizedInfo["ExpirationDateFormatted"] = dateFormatter.string(from: date)
            let expStatus: String
            let dateComponents = calendar.dateComponents(Set([.day]), from: .now, to: date)
            synthesizedInfo["ExpirationSummary"] = date.expirationString
            if date.compare(.now) == .orderedAscending {
                expStatus = "expired"
            } else if let day = dateComponents.day, day < 30 {
                expStatus = "expiring"
            } else {
                expStatus = "valid"
            }
            synthesizedInfo["ExpStatus"] = expStatus
        }
        // team信息
        if let teams: [String] = propertyList.value(key: "TeamIdentifier") {
            synthesizedInfo["TeamIds"] = teams.joined(separator: ", ")
        }
        // 描述文件
        /*
         if let entitlementsPropertyList = codesignEntitlementsData?.xmlToDictionary {
             let dictionaryFormatted = displayKeyAndValue(value: entitlementsPropertyList)
             synthesizedInfo["EntitlementsFormatted"] = "<pre>\(dictionaryFormatted)</pre>"
         }
         */
        if let entitlements = entitlements {
            let dictionaryFormatted = displayKeyAndValue(value: entitlements.values)
            synthesizedInfo["EntitlementsFormatted"] = "<pre>\(dictionaryFormatted)</pre>"
        } else if let dic: [String: Any] = propertyList.value(key: "Entitlements") {
            getTaskAllow = dic.value(key: "get-task-allow") ?? false
            let dictionaryFormatted = displayKeyAndValue(value: dic)
            synthesizedInfo["EntitlementsFormatted"] = "<pre>\(dictionaryFormatted)</pre>"
        } else {
            synthesizedInfo["EntitlementsFormatted"] = "No Entitlements"
        }
        // 开发者
        if let array = propertyList["DeveloperCertificates"] as? [Data] {
            synthesizedInfo["DeveloperCertificatesFormatted"] = formatter(certificates: array)
        } else {
            synthesizedInfo["DeveloperCertificatesFormatted"] = "No Developer Certificates"
        }
        // 测试设备
        if let array = propertyList["ProvisionedDevices"] as? [String] {
            hasDevices = !array.filter({ !$0.isEmpty }).isEmpty
            let devices = formattedDevices(array)
            synthesizedInfo = synthesizedInfo.merging(devices, uniquingKeysWith: { _, new in new })
        } else {
            synthesizedInfo["ProvisionedDevicesFormatted"] = "No Devices"
            synthesizedInfo["ProvisionedDevicesCount"] = "Distribution Profile"
        }
        let profileString = String(data: data, encoding: .utf8)?.escapedXML ?? ""
        synthesizedInfo["RawData"] = "<pre>\(profileString)</pre>"
        if propertyList["TeamName"] == nil {
            synthesizedInfo["TeamName"] = "<em>Team name not available</em>"
        }
        if propertyList["TeamIdentifier"] == nil {
            synthesizedInfo["TeamIds"] = "<em>Team ID not available</em>"
        }
        if propertyList["AppIDName"] == nil {
            synthesizedInfo["AppIDName"] = "<em>App name not available</em>"
        }
        let isEnterprise: Bool = propertyList.value(key: "ProvisionsAllDevices") ?? false
        if dataType == .Provision_macOS {
            synthesizedInfo["Platform"] = "mac"
            synthesizedInfo["ProfilePlatform"] = "Mac"
            synthesizedInfo["ProfileType"] = hasDevices ? "Development" : "Distribution (App Store)"
        } else {
            synthesizedInfo["Platform"] = "ios"
            synthesizedInfo["ProfilePlatform"] = "iOS"
            synthesizedInfo["ProfileType"] = hasDevices ? (getTaskAllow ? "Development" : "Distribution (Ad Hoc)") : (isEnterprise ? "Enterprise" : "Distribution (App Store)")
        }
    }
    
    /// 读取文件大小，创建时间
    private func readFileInfo() {
        synthesizedInfo["FileName"] = url.lastPathComponent.escapedXML
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        if let date = url.fileModificationDate, let size = try? url.sizeOnDisk() {
            synthesizedInfo["FileInfo"] = "\(size), 创建于 \(dateFormatter.string(from: date))"
        } else {
            synthesizedInfo["FileInfo"] = ""
        }
    }
    
    /// 将所有信息以网页的形式显示
    private func showHtml(web: WKWebView) {
        synthesizedInfo.forEach {
            html = html.replacingOccurrences(of: "__\($0.0)__", with: $0.1)
        }
        try? html.write(toFile: "/Users/zhouziyuan/Desktop/1.html", atomically: true, encoding: .utf8)
        let showHtml = self.html
        DispatchQueue.main.async {
            web.loadHTMLString(showHtml, baseURL: nil)
        }
    }
    
    /// 字典按层级类型组装
    func displayKeyAndValue(level: Int = 0, key: String? = nil, value: Any) -> String {
        let indent = " " * (level * 4)
        var out = ""
        if let dic = value as? [String: Any] {
            if let key = key, !key.isEmpty {
                out.append("\(indent)\(key) = {\n")
            } else if level != 0 {
                out.append("\(indent){\n")
            }
            let keys = dic.keys.sorted(by: <)
            for subKey in keys {
                let subLevel = (key == nil && level == 0) ? 0 : level + 1
                let res = displayKeyAndValue(level: subLevel, key: subKey, value: dic[subKey]!)
                out.append(res)
            }
            if level != 0 {
                out.append("\(indent)}\n")
            }
        } else if let array = value as? [Any] {
            out.append("\(indent)\(key ?? "") = (\n")
            array.forEach {
                let res = displayKeyAndValue(level: level + 1, key: nil, value: $0)
                out.append(res)
            }
            out.append("\(indent)}\n")
        } else if let data = value as? Data {
            if let key = key {
                out.append("\(indent)\(key) = \(data.count) bytes of data\n")
            } else {
                out.append("\(indent)\(data.count) bytes of data\n")
            }
        } else {
            if let key = key {
                out.append("\(indent)\(key) = \(value)\n")
            } else {
                out.append("\(indent)\(value)\n")
            }
        }
        return out
    }
    
    /// 获取证书信息
    func formatter(certificates: [Data]) -> String {
        let devCertSummaryKey = "summary"
        let devCertInvalidityDateKey = "invalidity"
        var certificateDetails = [[String: Any]]()
        for data in certificates {
            guard let cfData = CFDataCreate(kCFAllocatorDefault, (data as NSData).bytes, data.count), let certificateRef = SecCertificateCreateWithData(nil, cfData) else { continue }
            guard let summary = SecCertificateCopySubjectSummary(certificateRef) as? String else {
                print("Could not get summary from certificate")
                continue
            }
            var detailsDict: [String: Any] = [devCertSummaryKey: summary]
            var error: Unmanaged<CFError>?
            if let valuesDict = SecCertificateCopyValues(certificateRef, [kSecOIDInvalidityDate] as? CFArray, &error) as? [CFString: AnyObject] {
                if let invalidityDateDictionaryRef = valuesDict[kSecOIDInvalidityDate] as? [CFString: AnyObject] {
                    if let invalidityRef = invalidityDateDictionaryRef[kSecPropertyKeyValue] {
                        if let invalidity = invalidityRef as? Date {
                            detailsDict[devCertInvalidityDateKey] = invalidity
                        } else {
                            let string = invalidityRef.description ?? ""
                            let invalidityDateFormatter = DateFormatter()
                            invalidityDateFormatter.locale = Locale(identifier: "zh_CN")
                            invalidityDateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
                            if let invalidityDate = invalidityDateFormatter.date(from: string) {
                                detailsDict[devCertInvalidityDateKey] = invalidityDate
                            }
                        }
                    } else {
                        print("No invalidity values in '\(summary)' certificate, dictionary = \(invalidityDateDictionaryRef)")
                    }
                } else {
                    print("No invalidity values in '\(summary)' certificate, dictionary = \(valuesDict)")
                }
            } else {
                print("Could not get values in '\(summary)' certificate, error = \(String(describing: error))")
            }
            certificateDetails.append(detailsDict)
        }
        var certificates = "<table>\n"
        let sortedCertificateDetails = certificateDetails.sorted(by: { ($0[devCertSummaryKey] as! String) < ($1[devCertSummaryKey] as! String) })
        for detailsDict in sortedCertificateDetails {
            guard let summary = detailsDict[devCertSummaryKey] as? String, let invalidityDate = detailsDict[devCertInvalidityDateKey] as? Date else { continue }
            var expiration = invalidityDate.expirationString
            if expiration.isEmpty {
                expiration = "<span class='warning'>No invalidity date in certificate</span>"
            }
            certificates.append("<tr><td>\(summary)</td><td>\(expiration)</td></tr>\n")
        }
        certificates.append("</table>\n")
        return certificates
    }
    
    /// 获取测试设备
    func formattedDevices(_ value: [String]) -> [String: String] {
        var devices = "<table>\n<tr><th></th><th>UDID</th></tr>\n"
        let specialUUIDs = specialDevices.filter({ value.contains($0.uuid.uppercased()) }).sorted(by: { $0.name < $1.name })
        if !specialUUIDs.isEmpty {
            let html = specialUUIDs.map({ "<tr><td><font color=\"#FF00FF\">\($0.name)</font></td><td>\($0.uuid.uppercased())</td></tr>\n" }).joined()
            devices.append(html)
            // 添加一行空白做为分隔
            devices.append("<tr><td></td><td>&nbsp;&nbsp;&nbsp;&nbsp;</td></tr>\n")
        }
        let allspecialUUIDs = specialUUIDs.map({ $0.uuid })
        // 特殊显示设备排除
        let sortArray = value.filter({ !allspecialUUIDs.contains($0) && !$0.isEmpty }).sorted(by: <)
        var currentPrefix = ""
        for device in sortArray {
            var displayPrefix = ""
            let devicePrefix = String(device.first!).uppercased()
            if currentPrefix != devicePrefix {
                currentPrefix = devicePrefix
                displayPrefix = "\(devicePrefix) ➞ "
            }
            devices.append("<tr><td>\(displayPrefix)</td><td>\(device.uppercased())</td></tr>\n")
        }
        devices.append("</table>\n")
        let result = [
            "ProvisionedDevicesFormatted": devices,
            "ProvisionedDevicesCount": "\(value.count) 台"
        ]
        return result
    }
}
