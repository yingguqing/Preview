//
//  AppScene.swift
//  ProjectConfusion
//
//  Created by zhouziyuan on 2022/8/28.
//

import SwiftUI

/// 所有子功能的枚举
enum WindowType: String, CaseIterable {
    case Provision

    /// 标题
    var title: String {
        switch self {
            case .Provision:
                return "测试设备"
        }
    }
    
    /// 子功能对应的UI界面
    var view: AnyView {
        switch self {
            case .Provision:
                return AnyView(ProvisionView())
        }
    }
    
    /// window显示的默认大小
    var defaultSize: CGSize {
        return CGSize(width: 560, height: 400)
    }
    
    /// 打开对应的window
    func open() {
        guard let url = URL(string: "YingguqingPreview://\(rawValue)") else { return }
        NSWorkspace.shared.open(url)
    }
}

struct AppScene: Scene {
    @State var window:WindowType
    
    var body: some Scene {
        WindowGroup(window.title, content: { window.view })
            .handlesExternalEvents(matching: Set(arrayLiteral: window.rawValue))
    }
}

