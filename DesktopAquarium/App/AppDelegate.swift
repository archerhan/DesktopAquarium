//
//  AppDelegate.swift
//  DesktopAquarium
//
//  Created by it on 2026/4/17.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let window = NSApplication.shared.windows.first else { return }
        
        window.styleMask = [.borderless, .fullSizeContentView]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        
        // 将窗口交给管理器接管
        WindowManager.shared.setupWindow(window)
    }
}
