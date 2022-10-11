//
//  UnzipFile.swift
//  QLProvision
//
//  Created by zhouziyuan on 2022/9/26.
//

import Foundation
import Zip
@_implementationOnly import Minizip

class UnZip {
    
    let url:URL
    var appPlist:Data?
    var provisionData:Data?
    var iconData:Data?
    var entitlements: Entitlements?
    private lazy var currentFold:URL = URL(fileURLWithPath: Paths.TeamPath(isDeleteOld: true))
    
    init(url:URL) {
        self.url = url
        //Zip.addCustomFileExtension("ipa")
    }
    
    func  run() throws {
        defer{ clear() }
        // 解压Info.plist和描述文件
        var regexs = [try! Regex("Payload/.*?\\.app/Info\\.plist"), try! Regex("Payload/.*?\\.app/embedded\\.mobileprovision")]
        let paths = try Zip.unzipFile(url, destination: currentFold, outRegexs: regexs)
        if let plistPath = paths.first(where: { $0.lastPathComponent == "Info.plist" }) {
            appPlist = try? Data(contentsOf: URL(fileURLWithPath: plistPath))
        }
        if let provisionPath = paths.first(where: { $0.lastPathComponent == "embedded.mobileprovision" }) {
            provisionData = try? Data(contentsOf: URL(fileURLWithPath: provisionPath))
        }
        guard let appPropertyList = appPlist?.xmlToDictionary else { return }
        // 解压MachO文件
        if let bundleExecutable: String = appPropertyList.value(key: "CFBundleExecutable") {
            regexs = [try! Regex("Payload/.*?\\.app/\(bundleExecutable)")]
            if let binaryPath = try Zip.unzipFile(url, destination: currentFold, outRegexs: regexs).first {
                entitlements = try? EntitlementsReader(binaryPath).readEntitlements()
            }
        }
        // 从Info.plist获取Icon的名称，优先使用120的
        let iconName = mainIconNameForApp(appPropertyList)
        regexs = [try! Regex("Payload/.*?\\.app/\(iconName).*?")]
        // 解压icon，优先使用高倍图
        guard let iconPath = try Zip.unzipFile(url, destination: currentFold, outRegexs: regexs).sorted(by: >).first else { return }
        iconData = try? Data(contentsOf: URL(fileURLWithPath: iconPath))
    }
    
    /// 从Info.plist里获取ipa包的图标名称
    private func mainIconNameForApp(_ dic: [String: Any]) -> String {
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
    
    func clear() {
        currentFold.path.pathRemove()
    }
}

extension URL {
    static func /(parent: URL, child: String) -> URL {
        return parent.appendingPathComponent(child)
    }
}

extension Array where Element == Regex {
    /// 内容是否匹配多个正则中的任意一个
    func isMatch(value: String) -> Bool {
        guard !isEmpty else { return true }
        for regex in self {
            guard regex.matches(value) else { continue }
            return true
        }
        return false
    }
}

/// 解压方法扩展，增加过滤文件路径的参数，过滤通过正则来匹配
extension Zip {
    @discardableResult
    class func unzipFile(_ zipFilePath: URL, destination: URL, overwrite: Bool = true, password: String? = nil, outRegexs:[Regex] = []) throws -> [String]  {
        
        // File manager
        let fileManager = FileManager.default
        
        // Check whether a zip file exists at path.
        let path = zipFilePath.path
        
        if fileManager.fileExists(atPath: path) == false {
            throw ZipError.fileNotFound
        }
        
        // Unzip set up
        var ret: Int32 = 0
        var crc_ret: Int32 = 0
        let bufferSize: UInt32 = 4096
        var buffer = Array<CUnsignedChar>(repeating: 0, count: Int(bufferSize))
        
        // Progress handler set up
        
        // Begin unzipping
        let zip = unzOpen64(path)
        defer {
            unzClose(zip)
        }
        if unzGoToFirstFile(zip) != UNZ_OK {
            throw ZipError.unzipFail
        }
        var outPaths = [String]()
        repeat {
            if let cPassword = password?.cString(using: String.Encoding.ascii) {
                ret = unzOpenCurrentFilePassword(zip, cPassword)
            }
            else {
                ret = unzOpenCurrentFile(zip);
            }
            if ret != UNZ_OK {
                throw ZipError.unzipFail
            }
            var fileInfo = unz_file_info64()
            memset(&fileInfo, 0, MemoryLayout<unz_file_info>.size)
            ret = unzGetCurrentFileInfo64(zip, &fileInfo, nil, 0, nil, 0, nil, 0)
            if ret != UNZ_OK {
                unzCloseCurrentFile(zip)
                throw ZipError.unzipFail
            }
            let fileNameSize = Int(fileInfo.size_filename) + 1
            //let fileName = UnsafeMutablePointer<CChar>(allocatingCapacity: fileNameSize)
            let fileName = UnsafeMutablePointer<CChar>.allocate(capacity: fileNameSize)

            unzGetCurrentFileInfo64(zip, &fileInfo, fileName, UInt(fileNameSize), nil, 0, nil, 0)
            fileName[Int(fileInfo.size_filename)] = 0

            var pathString = String(cString: fileName)
            
            guard pathString.count > 0 else {
                throw ZipError.unzipFail
            }

            guard outRegexs.isEmpty || outRegexs.isMatch(value: pathString) else {
                ret = unzGoToNextFile(zip)
                continue
            }
            var isDirectory = false
            let fileInfoSizeFileName = Int(fileInfo.size_filename-1)
            if (fileName[fileInfoSizeFileName] == "/".cString(using: String.Encoding.utf8)?.first || fileName[fileInfoSizeFileName] == "\\".cString(using: String.Encoding.utf8)?.first) {
                isDirectory = true;
            }
            free(fileName)
            if pathString.rangeOfCharacter(from: CharacterSet(charactersIn: "/\\")) != nil {
                pathString = pathString.replacingOccurrences(of: "\\", with: "/")
            }

            let fullPath = destination.appendingPathComponent(pathString).path
            
            outPaths.append(fullPath)
            let creationDate = Date()

            let directoryAttributes: [FileAttributeKey: Any]? = [.creationDate : creationDate, .modificationDate : creationDate]

            do {
                if isDirectory {
                    try fileManager.createDirectory(atPath: fullPath, withIntermediateDirectories: true, attributes: directoryAttributes)
                }
                else {
                    let parentDirectory = (fullPath as NSString).deletingLastPathComponent
                    try fileManager.createDirectory(atPath: parentDirectory, withIntermediateDirectories: true, attributes: directoryAttributes)
                }
            } catch {}
            if fileManager.fileExists(atPath: fullPath) && !isDirectory && !overwrite {
                unzCloseCurrentFile(zip)
                ret = unzGoToNextFile(zip)
            }

            var writeBytes: UInt64 = 0
            var filePointer: UnsafeMutablePointer<FILE>?
            filePointer = fopen(fullPath, "wb")
            while filePointer != nil {
                let readBytes = unzReadCurrentFile(zip, &buffer, bufferSize)
                if readBytes > 0 {
                    guard fwrite(buffer, Int(readBytes), 1, filePointer) == 1 else {
                        throw ZipError.unzipFail
                    }
                    writeBytes += UInt64(readBytes)
                }
                else {
                    break
                }
            }

            if let fp = filePointer { fclose(fp) }

            crc_ret = unzCloseCurrentFile(zip)
            if crc_ret == UNZ_CRCERROR {
                throw ZipError.unzipFail
            }
            guard writeBytes == fileInfo.uncompressed_size else {
                throw ZipError.unzipFail
            }

            //Set file permissions from current fileInfo
            if fileInfo.external_fa != 0 {
                let permissions = (fileInfo.external_fa >> 16) & 0x1FF
                //We will devifne a valid permission range between Owner read only to full access
                if permissions >= 0o400 && permissions <= 0o777 {
                    do {
                        try fileManager.setAttributes([.posixPermissions : permissions], ofItemAtPath: fullPath)
                    } catch {
                        print("Failed to set permissions to file \(fullPath), error: \(error)")
                    }
                }
            }

            ret = unzGoToNextFile(zip)
        } while (ret == UNZ_OK && ret != UNZ_END_OF_LIST_OF_FILE)
        return outPaths
    }
}
