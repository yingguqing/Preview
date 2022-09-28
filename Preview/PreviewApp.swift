//
//  PreviewMarkdownApp.swift
//  PreviewMarkdown
//
//  Created by zhouziyuan on 2022/9/20.
//

import SwiftUI

@main
struct PreviewApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        AppScene(window: .Provision)
    }
}

// Provision

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        let itemTitles = ["File", "View", "Window", "Help"]
        NSApp.mainMenu?.items.filter({ itemTitles.contains($0.title) }).forEach {
            NSApp.mainMenu?.removeItem($0)
        }
        NSApp.windows.first?.setContentSize(CGSize(width: 400, height: 600))
    }

    // 重新设置window默认显示宽高
    /*
     func application(_ application: NSApplication, open _: [URL]) {
         let titles = WindowType.allCases.map { $0.title }
         guard let window = application.windows.filter({ titles.contains($0.title) }).last, let type = WindowType.allCases.filter({ $0.title == window.title }).first else { return }
         window.setContentSize(type.defaultSize)
     }
     */

    // 关闭界面时,true为同时关闭程序，false为最小化程序
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_: Notification) {
        _ = Process.execute("/usr/bin/qlmanage", arguments: ["-r", "cache"])
        //_ = Process.execute(CommandLine.Qlmanage, arguments: ["-r"])
    }
}
