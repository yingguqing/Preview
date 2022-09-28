//
//  Helper.swift
//  Preview
//
//  Created by zhouziyuan on 2022/9/21.
//

import Foundation

enum DataType: String {
    case Ipa = "com.apple.itunes.ipa"
    case Provision_iOS = "com.apple.mobileprovision"
    case Provision_macOS = "com.apple.provisionprofile"
    case Archive = "com.apple.xcode.archive"
}

let APP_CODE_PREVIEWER = Bundle.main.bundleIdentifier ?? "com.yingguqing.Preview.QLProvision"
enum Errors {
    static let Invalid = NSError(domain: APP_CODE_PREVIEWER, code: 400, userInfo: [NSLocalizedDescriptionKey: "文件不是ipa、archive或mobileprovision中的任意一种"])
    static let ReadFaild = NSError(domain: APP_CODE_PREVIEWER, code: 401, userInfo: [NSLocalizedDescriptionKey: "文件解析失败"])
}

enum Paths {
    static let UserHomePath: String = NSString(string: "~").expandingTildeInPath
    static let DesktopPath: String = UserHomePath / "Desktop"
    static let HeaderFilePath: String = "/FlatSDK/Class/Public/FlatSDK.h"
    static let ConfigFilePath: String = "FlatSDK/FlatSDK/Resource/Config.plist"
    static let ProvisioningProfilesPath: String = UserHomePath / "Library/MobileDevice/Provisioning Profiles"
    /// 创建沙盒的临时目录
    static func TeamPath(fold: String = "", isDeleteOld: Bool = true) -> String {
/*
        var path = (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last ?? NSTemporaryDirectory()) / "\(Bundle.main.bundleIdentifier ?? "快速查看")"
        path = path / fold
        path.createFilePath(isDelOldPath: isDeleteOld)
        return path
*/
        var path = NSTemporaryDirectory() / "\(Bundle.main.bundleIdentifier ?? "快速查看")"
        path = path / fold
        print(path)
        path.createFilePath(isDelOldPath: isDeleteOld)
        return path
    }
}


/// 正常需要命令路径
enum CommandLine {
    static let Unzip = "/usr/bin/unzip"
    static let CodeSign = "/usr/bin/codesign"
}

extension String {
    var escapedXML: String {
        var string = self
        let htmlEntityReplacement = [
            ("&", "&amp;"),
            ("\"", "&quot;"),
            ("'", "&apos;"),
            ("<", "&lt;"),
            (">", "&gt;")
        ]
        htmlEntityReplacement.forEach {
            string = string.replacingOccurrences(of: $0.0, with: $0.1)
        }
        return string
    }
}

extension URL {
    var fileModificationDate: Date? {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: self.path)
            return attr[.modificationDate] as? Date
        } catch {
            return nil
        }
    }

    /// check if the URL is a directory and if it is reachable
    func isDirectoryAndReachable() throws -> Bool {
        guard try resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else {
            return false
        }
        return try checkResourceIsReachable()
    }

    /// returns total allocated size of a the directory including its subFolders or not
    func directoryTotalAllocatedSize(includingSubfolders: Bool = false) throws -> Int? {
        guard try isDirectoryAndReachable() else { return nil }
        if includingSubfolders {
            guard
                let urls = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.allObjects as? [URL] else { return nil }
            return try urls.lazy.reduce(0) {
                (try $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0) + $0
            }
        }
        return try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil).lazy.reduce(0) {
            (try $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                .totalFileAllocatedSize ?? 0) + $0
        }
    }

    /// returns the directory total size on disk
    func sizeOnDisk() throws -> String? {
        if try isDirectoryAndReachable() {
            guard let size = try directoryTotalAllocatedSize(includingSubfolders: true) else { return nil }
            URL.byteCountFormatter.countStyle = .file
            guard let byteCount = URL.byteCountFormatter.string(for: size) else { return nil }
            return byteCount
        } else {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: self.path)
            guard let size = fileAttributes[.size] as? Int else { return nil }
            guard let byteCount = URL.byteCountFormatter.string(for: size) else { return nil }
            return byteCount
        }
    }

    private static let byteCountFormatter = ByteCountFormatter()
}

extension Date {
    /// 过期
    var expirationString: String {
        var result = ""
        let calendar = Calendar.current
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        let dateComponents = calendar.dateComponents(Set([.day, .hour, .minute]), from: .now, to: self)
        if self.compare(.now) == .orderedAscending {
            if calendar.isDate(self, inSameDayAs: .now) {
                result = "<span>Expired today</span>"
            } else {
                let reverseDateComponents = calendar.dateComponents(Set([.day, .hour, .minute]), from: self, to: .now)
                result = "<span>过期 \(formatter.string(from: reverseDateComponents)?.replacingOccurrences(of: "days", with: "天") ?? "??")</span>"
            }
        } else {
            if let day = dateComponents.day, day == 0 {
                result = "<span>今天过期</span>"
            } else if let day = dateComponents.day, day < 30 {
                result = "<span>\(formatter.string(from: dateComponents)?.replacingOccurrences(of: "days", with: "天后过期") ?? "??")</span>"
            } else {
                result = "\(formatter.string(from: dateComponents)?.replacingOccurrences(of: "days", with: "天后过期")  ?? "??")"
            }
        }
        return result
    }
}

extension Dictionary where Key == String {
    func formatXML(replacements: [String: String], level: Int = 0) -> String {
        var string = ""
        for (key, value) in self {
            let localizedKey = replacements[key] ?? key
            for _ in 0 ..< level {
                string.append(level == 1 ? "- " : "&nbsp;&nbsp;")
            }
            if let dic: [String: Any] = self.value(key: key) {
                let object = dic.formatXML(replacements: replacements, level: level + 1)
                string.append("\(localizedKey):<div class=\"list\">\(object)</div>")
            } else if let obj: Bool = self.value(key: key) {
                string.append("\(localizedKey): \(obj ? "YES" : "NO")<br />")
            } else {
                string.append("\(localizedKey): \(value)<br />")
            }
        }
        return string
    }
}

extension Data {
    var xmlToDictionary: [String: Any]? {
        var propertyListForamt = PropertyListSerialization.PropertyListFormat.xml
        do {
            return try PropertyListSerialization.propertyList(from: self, options: .mutableContainersAndLeaves, format: &propertyListForamt) as? [String: Any]
        } catch {
            print("xml数据转字典失败：\(error.localizedDescription)")
            return nil
        }
    }
}
