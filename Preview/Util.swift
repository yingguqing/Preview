//
//  Util.swift
//  PreviewMarkdown
//
//  Created by zhouziyuan on 2022/9/20.
//

import SwiftUI

protocol JsonKey {
    var key: String { get }
}

extension String: JsonKey {
    var key: String {
        return self
    }
}

extension Dictionary where Key == String {
    var jsonData: Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [.sortedKeys, .prettyPrinted])
    }

    var jsonString: String? {
        guard let data = jsonData else { return nil }
        return String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\/", with: "/")
    }

    func value<T>(key: JsonKey) -> T? {
        guard let value = self[key.key] else { return nil }
        if T.self == Int.self {
            var result: Int?
            if let val = value as? Int {
                result = val
            } else if let val = value as? String {
                result = Int(val)
            } else if let val = value as? Double {
                result = Int(val)
            } else if let val = value as? Bool {
                result = (val ? 1 : 0)
            }
            return result as? T
        } else if T.self == String.self {
            var result: String?
            if let val = value as? Int {
                result = String(val)
            } else if let val = value as? String {
                result = val
            } else if let val = value as? Double {
                result = String(val)
            } else if let val = value as? Bool {
                result = (val ? "true" : "false")
            }
            return result as? T
        } else if T.self == Bool.self {
            var result: Bool?
            if let val = value as? Int {
                result = val != 0
            } else if let val = value as? String {
                let low = val.lowercased()
                if low == "true" || low == "1" {
                    result = true
                } else if low == "false" || low == "0" {
                    result = false
                } else {
                    result = !val.isEmpty
                }
            } else if let val = value as? Double {
                result = val != 0
            } else if let val = value as? Bool {
                result = val
            }
            return result as? T
        } else if T.self == Double.self {
            var result: Double?
            if let val = value as? Int {
                result = Double(val)
            } else if let val = value as? String {
                result = Double(val)
            } else if let val = value as? Double {
                result = val
            } else if let val = value as? Bool {
                result = Double(val ? 1 : 0)
            }
            return result as? T
        } else {
            return value as? T
        }
    }
}

extension NSColor {
    var hexString: String {
        guard let rgbColour = usingColorSpace(.sRGB) else {
            return "00FF00FF"
        }

        let red = Int(round(rgbColour.redComponent * 0xFF))
        let green = Int(round(rgbColour.greenComponent * 0xFF))
        let blue = Int(round(rgbColour.blueComponent * 0xFF))
        let alpha = Int(round(rgbColour.alphaComponent * 0xFF))

        let hexString = NSString(format: "%02X%02X%02X%02X", red, green, blue, alpha)
        return hexString as String
    }

    convenience init?(_ hex: String?) {
        guard let hex = hex?.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) else { return nil }
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            default:
                return nil
        }
        self.init(srgbRed: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, alpha: Double(a) / 255)
    }

    class func hexToColour(_ hex: String) -> NSColor {
        return NSColor(hex) ?? .white
    }
}


