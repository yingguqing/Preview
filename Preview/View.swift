//
//  Util.swift
//  PreviewMarkdown
//
//  Created by zhouziyuan on 2022/9/20.
//

import SwiftUI


struct AppIcon: View {
    var body: some View {
        Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
            .resizable()
    }
}

struct NiceButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    var foregroundColor: Color
    var backgroundColor: Color
    var pressedColor: Color

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(10)
            .foregroundColor(foregroundColor)
            .background((configuration.isPressed || !isEnabled) ? pressedColor : backgroundColor)
            .cornerRadius(5)
    }
}

extension View {
    /// 按钮样式（背景，字体颜色，不可操作背景）
    /// - Parameters:
    ///   - foregroundColor: 字体颜色
    ///   - backgroundColor: 正常背景颜色
    ///   - pressedColor: 不可操作时背景颜色
    func niceButton(foregroundColor: Color = .white, backgroundColor: Color = .gray, pressedColor: Color = .accentColor) -> some View {
        buttonStyle(
            NiceButtonStyle(
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
                pressedColor: pressedColor
            )
        )
    }

    /// 控件描边
    /// - Parameters:
    ///   - cornerRadius: 圆角半径
    ///   - color: 描边颜色
    ///   - lineWidth: 描边线宽度
    func border(cornerRadius: CGFloat = 5, color: Color = .gray, lineWidth: Double = 0.5) -> some View {
        overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(color, lineWidth: lineWidth))
    }
}

extension Color {
    
}
