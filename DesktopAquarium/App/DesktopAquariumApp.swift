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
        
        MenuBarExtra("水族馆控制", systemImage: "fish") {
            Picker("窗口层级", selection: $windowManager.currentLevel) {
                Text("沉底（桌面背景）").tag(AquariumLevel.background)
                Text("置顶（覆盖窗口）").tag(AquariumLevel.floating)
            }
            .pickerStyle(.inline)
            
            Divider()
            
            Toggle("开启鼠标穿透", isOn: $windowManager.isClickThrough)
            
            Divider()
            
            Button("退出水族馆"){
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
