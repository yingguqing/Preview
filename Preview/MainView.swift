//
//  ContentView.swift
//  PreviewMarkdown
//
//  Created by zhouziyuan on 2022/9/20.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        VStack {
            AppIcon()
                .frame(width: 64, height: 64)
            Text("Preview 为 ipa、archive、mobileprovision 文件提供 Quick Look 预览。\n运行一次此应用程序以注册其 预览 应用程序扩展，然后您可以在 系统偏好设置 > 扩展 > 快速查看 中进行管理")
            .multilineTextAlignment(.center)
            .padding(.top, 20)
            .font(.system(size: 15))
            Button(action: {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Extensions.prefPane"))
            }) {
                Text("打开系统偏好设置")
                    .frame(width: 150, height: 6)
                    .font(.system(size: 16))
            }
            .niceButton()
            Text("如果无法预览，通常可以通过以下方式解决,注销您的 Mac 帐户，再次登录并重新运行此应用程序。")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .padding(.top, 30)
            Button(action: {
                WindowType.Provision.open()
            }) {
                Text("显示添加测试设备特殊显示设置")
                    .frame(height: 6)
                    .font(.system(size: 16))
            }
            .padding(.top, 15)
            .niceButton()
            Spacer()
            Text("PreviewMarkdown © 2022, 影孤清.  Contains ProvisionQL © 2020, ealeksandrov;")
                .multilineTextAlignment(.center)
        }
        .frame(width: 610, height: 432)
        .padding()
    }
}



struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

