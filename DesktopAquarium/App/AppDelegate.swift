//
//  AppDelegate.swift
//  DesktopAquarium
//
//  Created by it on 2026/4/17.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // 🚀 声明状态栏核心对象
    var statusItem: NSStatusItem!
    var interactiveMenuItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let window = NSApplication.shared.windows.first else { return }
        
        window.styleMask = [.borderless, .fullSizeContentView]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        
        // 将窗口交给管理器接管
        WindowManager.shared.setupWindow(window)
        
        setupStatusBar()
    }
    // MARK: - 状态栏菜单系统 (兼容 macOS 11+)
    private func setupStatusBar() {
        // 1. 创建状态栏图标（长度自适应）
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "fish", accessibilityDescription: "水族馆")
        }
        
        // 2. 创建主菜单
        let menu = NSMenu()
        
        // --- 菜单项 1：投喂/交互模式 ---
        interactiveMenuItem = NSMenuItem(
            title: "🐟 投喂/交互模式",
            action: #selector(toggleInteractive),
            keyEquivalent: "f"
        )
        // 根据当前的系统状态设置是否打钩
        interactiveMenuItem.state = WindowManager.shared.isInteractive ? .on : .off
        menu.addItem(interactiveMenuItem)
        
        // 分割线
        menu.addItem(NSMenuItem.separator())
        
        // --- 菜单项 2：背景设置 (带子菜单) ---
        let bgMenuItem = NSMenuItem(title: "背景设置", action: nil, keyEquivalent: "")
        let bgMenu = NSMenu()
        
        // 循环添加我们在 WindowManager 里定义的背景枚举
        for bg in AquariumBackground.allCases {
            let item = NSMenuItem(
                title: bg.rawValue,
                action: #selector(changeBackground(_:)),
                keyEquivalent: ""
            )
            // 把枚举值绑在对象里传过去
            item.representedObject = bg
            if WindowManager.shared.selectedBackground == bg {
                item.state = .on // 勾选当前背景
            }
            bgMenu.addItem(item)
        }
        bgMenuItem.submenu = bgMenu
        menu.addItem(bgMenuItem)
        
        // 分割线
        menu.addItem(NSMenuItem.separator())
        
        // --- 菜单项 3：退出 ---
        menu.addItem(NSMenuItem(title: "退出水族馆", action: #selector(quitApp), keyEquivalent: "q"))
        
        // 3. 将组装好的菜单挂载到状态栏上
        statusItem.menu = menu
    }
    
    // MARK: - 菜单点击响应事件
    
    @objc private func toggleInteractive() {
        // 切换布尔值
        let newState = !WindowManager.shared.isInteractive
        WindowManager.shared.isInteractive = newState
        
        // 更新菜单的 UI 勾选状态
        interactiveMenuItem.state = newState ? .on : .off
    }
    
    @objc private func changeBackground(_ sender: NSMenuItem) {
        guard let bg = sender.representedObject as? AquariumBackground else { return }
        
        // 更新后台数据
        WindowManager.shared.selectedBackground = bg
        
        // 刷新单选框 UI：把同级菜单的所有选项都设为 off，只把当前点击的设为 on
        if let menu = sender.menu {
            for item in menu.items {
                item.state = (item == sender) ? .on : .off
            }
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
