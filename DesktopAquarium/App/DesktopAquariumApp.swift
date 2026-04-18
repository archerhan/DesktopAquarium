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
    
    // 注入 WindowManager 状态
    @StateObject private var windowManager = WindowManager.shared

    var body: some Scene {
        // 保留你原来的主窗口逻辑
        WindowGroup {
            ContentView()
        }
    }
}
