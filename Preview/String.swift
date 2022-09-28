//
//  String.swift
//  Preview
//
//  Created by zhouziyuan on 2022/9/21.
//

import Foundation

extension String {

    // 路径拼接 "/a/b" / "c.mp3" = "/a/b/c.mp3"
    static func /(parent: String, child: String) -> String {
        return (parent as NSString).appendingPathComponent(child)
    }

    // 字符串乘法。比如 .*2=..

    static func *(parent: String, child: Int) -> String {
        if child < 0 {
            return parent
        } else if child == 0 {
            return ""
        } else {
            let array = [String](repeating: parent, count: child)
            return array.joined()
        }
    }

    /// 获得文件的扩展类型（不带'.'）
    var pathExtension: String {
        return (self as NSString).pathExtension
    }

    /// 从路径中获得完整的文件名（带后缀）
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }

    /// 删除最后一个/后面的内容 可以是整个文件名,可以是文件夹名
    var deletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }

    /// 获得文件名（不带后缀）
    var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }

    /// 删除后缀的文件名
    var fileNameWithoutExtension: String {
        return self.lastPathComponent.deletingPathExtension
    }

    var isValidPath: Bool {
        guard !isEmpty else {
            return false
        }
        if hasPrefix("/") {
            return true
        }
        assertionFailure("\(self) 不是一个合法路径")
        return false
    }

    /// 文件是否存在
    var fileExists: Bool {
        guard isValidPath else {
            return false
        }
        return FileManager.default.fileExists(atPath: self)
    }

    /// 目录是否存在，非目录时，返回false
    var directoryExists: Bool {
        guard isValidPath else {
            return false
        }
        var isDirectory = ObjCBool(booleanLiteral: false)
        let isExists = FileManager.default.fileExists(atPath: self, isDirectory: &isDirectory)
        return isDirectory.boolValue && isExists
    }

    // 生成目录所有文件

    @discardableResult func createFilePath(isDelOldPath: Bool = false) -> String {
        guard isValidPath else {
            return self
        }
        do {
            if isDelOldPath, self.fileExists {
                self.pathRemove()
            } else if self.fileExists {
                return self
            }
            try FileManager.default.createDirectory(atPath: self, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("创建目录失败 \(error.localizedDescription)")
        }
        return self
    }

    /// 字符串写成文件，可以提升权限
    ///
    /// - Parameters:
    ///   - path: 写成文件路径
    ///   - permissions: 是否提升权限到777
    func write(toFile path: String, permissions: Bool = false) throws {
        if path.fileExists {
            path.pathRemove()
        }
        try self.write(toFile: path, atomically: true, encoding: .utf8)
        guard permissions else {
            return
        }
        // 将文件的权限设为777,可执行
        let atributes = [FileAttributeKey.posixPermissions: 0o777]
        try FileManager.default.setAttributes(atributes, ofItemAtPath: path)
    }

    func pathRemove() {
        guard isValidPath, self.fileExists else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: self)
        } catch let error as NSError {
            print("文件删除失败 \(error.localizedDescription)")
        }
    }

    var base64Encoding: String {
        guard self.isEmpty == false else {
            return ""
        }
        if let plainData = self.data(using: .utf8) {
            let base64String = plainData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            return base64String
        }
        return ""
    }

    var base64Decoding: String {
        guard self.isEmpty == false else {
            return ""
        }
        if let decodedData = Data(base64Encoded: self),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            return decodedString
        }
        return ""
    }

    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        return String(self[start...])
    }
}
