//
//  WindowManager.swift
//  DesktopAquarium
//
//  Created by it on 2026/4/18.
//

import AppKit
import Combine

// 定义窗口层级枚举
enum AquariumLevel {
    case background // 沉底（贴近桌面背景）
    case floating   // 置顶（悬浮在所有窗口之上）
}

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    // 弱引用主窗口，避免内存泄漏
    private weak var window: NSWindow?
    
    // 发布点击穿透状态
    @Published var isClickThrough: Bool = false {
        didSet {
            window?.ignoresMouseEvents = isClickThrough
        }
    }
    
    // 发布当前层级状态
    @Published var currentLevel: AquariumLevel = .floating {
        didSet {
            updateWindowLevel()
        }
    }
    
    // 绑定窗口并进行初始配置
    func setupWindow(_ window: NSWindow) {
        self.window = window
        
        // 关键配置：让窗口可以在所有工作区显示，固定位置，且不参与 Cmd+Tab 循环
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        // 应用初始状态
        updateWindowLevel()
        window.ignoresMouseEvents = isClickThrough
    }
    
    private func updateWindowLevel() {
        guard let window = window else { return }
        switch currentLevel {
        case .floating:
            // 置顶层级
            window.level = .floating
        case .background:
            // 沉底层级：设定在桌面图标之下/之上，完美伪装成壁纸的一部分
            window.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)))
        }
    }
}
