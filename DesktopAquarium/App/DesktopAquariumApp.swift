//
//  DesktopAquariumApp.swift
//  DesktopAquarium
//
//  Created by it on 2026/4/17.
//

import SwiftUI

@main
struct DesktopAquariumApp: App {
    // 注入 AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var windowManager = WindowManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // 隐藏默认的窗口标题栏行为
        .windowStyle(.hiddenTitleBar)
        
//        MenuBarExtra("水族馆控制", systemImage: "fish") {
//            
//            Button("退出水族馆"){
//                NSApplication.shared.terminate(nil)
//            }
//            .keyboardShortcut("q")
//        }
    }
}
