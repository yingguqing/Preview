//
//  NSImage.swift
//  QLProvision
//
//  Created by zhouziyuan on 2022/9/22.
//

import Cocoa

extension NSImage {
    var roundCorners: NSImage {
        let existingSize = self.size
        let composedImage = NSImage(size: existingSize)

        composedImage.lockFocus()
        let ctx = NSGraphicsContext.current
        ctx?.imageInterpolation = .high

        let imageFrame = NSRect(origin: .zero, size: existingSize)
        let clipPath = NSBezierPath(roundedRect: imageFrame, cornerRadius: existingSize.width * 0.225)
        clipPath.windingRule = .evenOdd
        clipPath.addClip()

        let rect = NSRect(origin: .zero, size: existingSize)
        self.draw(at: .zero, from: rect, operation: .sourceOver, fraction: 1)
        composedImage.unlockFocus()

        return composedImage
    }
}

private extension CGRect {
    func topLeft(x: CGFloat, y: CGFloat, radius: CGFloat) -> NSPoint {
        var point = self.origin
        point.x += x * radius
        point.y += y * radius
        return point
    }

    func topRight(x: CGFloat, y: CGFloat, radius: CGFloat) -> NSPoint {
        var point = self.origin
        point.x += self.size.width - x * radius
        point.y += y * radius
        return point
    }

    func bottomRight(x: CGFloat, y: CGFloat, radius: CGFloat) -> NSPoint {
        var point = self.origin
        point.x += self.size.width - x * radius
        point.y += self.size.height - y * radius
        return point
    }

    func bottomLeft(x: CGFloat, y: CGFloat, radius: CGFloat) -> NSPoint {
        var point = self.origin
        point.x += x * radius
        point.y += self.size.height - y * radius
        return point
    }
}

extension NSBezierPath {
    convenience init(roundedRect: NSRect, cornerRadius: CGFloat) {
        self.init()
        let limit = min(roundedRect.size.width, roundedRect.size.height) / 2 / 1.52866483
        let limiteRadius = min(limit, cornerRadius)
        
        self.move(to: roundedRect.topLeft(x: 1.52866483, y: 0, radius: limiteRadius))
        self.line(to: roundedRect.topRight(x: 1.52866471, y: 0, radius: limiteRadius))
        self.curve(to: roundedRect.topRight(x: 0.66993427, y: 0.06549600, radius: limiteRadius), controlPoint1: roundedRect.topRight(x: 1.08849323, y: 0.00000000, radius: limiteRadius), controlPoint2: roundedRect.topRight(x: 0.86840689, y: 0.00000000, radius: limiteRadius))
        self.line(to: roundedRect.topRight(x: 0.63149399, y: 0.07491100, radius: limiteRadius))
        self.curve(to: roundedRect.topRight(x: 0.07491176, y: 0.63149399, radius: limiteRadius), controlPoint1: roundedRect.topRight(x: 0.37282392, y: 0.16905899, radius: limiteRadius), controlPoint2: roundedRect.topRight(x: 0.16906013, y: 0.37282401, radius: limiteRadius))
        self.curve(to: roundedRect.topRight(x: 0.00000000, y: 1.52866483, radius: limiteRadius), controlPoint1: roundedRect.topRight(x: 0.00000000, y: 0.86840701, radius: limiteRadius), controlPoint2: roundedRect.topRight(x: 0.00000000, y: 1.08849299, radius: limiteRadius))
        self.line(to: roundedRect.bottomRight(x: 0.00000000, y: 1.52866471, radius: limiteRadius))
        self.curve(to: roundedRect.bottomRight(x: 0.06549569, y: 0.66993493, radius: limiteRadius), controlPoint1: roundedRect.bottomRight(x: 0.00000000, y: 1.08849323, radius: limiteRadius), controlPoint2: roundedRect.bottomRight(x: 0.00000000, y: 0.86840689, radius: limiteRadius))
        self.line(to: roundedRect.bottomRight(x:0.07491111, y: 0.63149399, radius: limiteRadius))
        self.curve(to: roundedRect.bottomRight(x: 0.63149399, y: 0.07491111, radius: limiteRadius), controlPoint1: roundedRect.bottomRight(x: 0.16905883, y: 0.37282392, radius: limiteRadius), controlPoint2: roundedRect.bottomRight(x: 0.37282392, y: 0.16905883, radius: limiteRadius))
        self.curve(to: roundedRect.bottomRight(x: 1.52866471, y: 0.00000000, radius: limiteRadius), controlPoint1: roundedRect.bottomRight(x: 0.86840689, y: 0.00000000, radius: limiteRadius), controlPoint2: roundedRect.bottomRight(x: 1.08849323, y: 0.00000000, radius: limiteRadius))
        self.line(to: roundedRect.bottomLeft(x:1.52866483, y: 0.00000000, radius: limiteRadius))
        self.curve(to: roundedRect.bottomLeft(x: 0.66993397, y: 0.06549569, radius: limiteRadius), controlPoint1: roundedRect.bottomLeft(x: 1.08849299, y: 0.00000000, radius: limiteRadius), controlPoint2: roundedRect.bottomLeft(x: 0.86840701, y: 0.00000000, radius: limiteRadius))
        self.line(to: roundedRect.bottomLeft(x:0.63149399, y: 0.07491111, radius: limiteRadius))
        self.curve(to: roundedRect.bottomLeft(x: 0.07491100, y: 0.63149399, radius: limiteRadius), controlPoint1: roundedRect.bottomLeft(x: 0.37282401, y: 0.16905883, radius: limiteRadius), controlPoint2: roundedRect.bottomLeft(x: 0.16906001, y: 0.37282392, radius: limiteRadius))
        self.curve(to: roundedRect.bottomLeft(x: 0.00000000, y: 1.52866471, radius: limiteRadius), controlPoint1: roundedRect.bottomLeft(x: 0.00000000, y: 0.86840689, radius: limiteRadius), controlPoint2: roundedRect.bottomLeft(x: 0.00000000, y: 1.08849323, radius: limiteRadius))
        self.line(to: roundedRect.topLeft(x:0.00000000, y: 1.52866483, radius: limiteRadius))
        self.curve(to: roundedRect.topLeft(x: 0.06549600, y: 0.66993397, radius: limiteRadius), controlPoint1: roundedRect.topLeft(x: 0.00000000, y: 1.08849299, radius: limiteRadius), controlPoint2: roundedRect.topLeft(x: 0.00000000, y: 0.86840701, radius: limiteRadius))
        self.line(to: roundedRect.topLeft(x:0.07491100, y: 0.63149399, radius: limiteRadius))
        self.curve(to: roundedRect.topLeft(x: 0.63149399, y: 0.07491100, radius: limiteRadius), controlPoint1: roundedRect.topLeft(x: 0.16906001, y: 0.37282401, radius: limiteRadius), controlPoint2: roundedRect.topLeft(x: 0.37282401, y: 0.16906001, radius: limiteRadius))
        self.curve(to: roundedRect.topLeft(x: 1.52866483, y: 0.00000000, radius: limiteRadius), controlPoint1: roundedRect.topLeft(x: 0.86840701, y: 0.00000000, radius: limiteRadius), controlPoint2: roundedRect.topLeft(x: 1.08849299, y: 0.00000000, radius: limiteRadius))
        self.close()
    }
}
