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
        .windowResizability(.contentSize)
        WindowGroup(id: "Provision") {
            ProvisionView()
        }
        .windowResizability(.contentSize)
    }
}

// Provision

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        let itemTitles = ["File", "View", "Window", "Help"]
        NSApp.mainMenu?.items.filter({ itemTitles.contains($0.title) }).forEach {
            NSApp.mainMenu?.removeItem($0)
        }
    }

    // 关闭界面时,true为同时关闭程序，false为最小化程序
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_: Notification) {
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/qlmanage")
            process.arguments = ["-r", "cache"]
            try process.run()
            process.waitUntilExit()
        } catch {
            print(error.localizedDescription)
        }
    }
}
