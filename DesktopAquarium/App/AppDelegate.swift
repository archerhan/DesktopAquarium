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
    var audioMenuItem: NSMenuItem! // 🚀 新增：音频菜单项引用
    var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 🚀 让 App 作为“附件”运行：不显示 Dock 图标，不出现在强制退出列表，纯净后台运行！
        NSApp.setActivationPolicy(.accessory)
        
        guard let window = NSApplication.shared.windows.first else { return }
        window.styleMask = [.borderless, .fullSizeContentView]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        
        // 将窗口交给管理器接管
        WindowManager.shared.setupWindow(window)
        
        setupStatusBar()
    }
    // MARK: - 现代状态栏 Popover 系统
    private func setupStatusBar() {
        // 1. 配置状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "fish", accessibilityDescription: "水族馆")
            // 点击图标时，触发 Popover 开关
            button.action = #selector(togglePopover(_:))
        }
        
        // 2. 初始化现代化悬浮窗
        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 300)
        popover.behavior = .transient // 🚀 关键：点击屏幕其他地方，面板自动收起！
        
        // 3. 将极其美观的 SwiftUI 视图塞进悬浮窗里
        popover.contentViewController = NSHostingController(rootView: ModernControlPanelView())
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                // 唤醒 App 获取焦点，确保按钮能够第一时间被点击
                NSApp.activate(ignoringOtherApps: true)
                // 在状态栏图标正下方弹出悬浮面板
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}

// MARK: - 现代控制面板 UI (SwiftUI)
struct ModernControlPanelView: View {
    @ObservedObject var windowManager = WindowManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 标题
            HStack {
                Image(systemName: "fish.fill")
                Text("水族馆控制台")
                    .font(.headline)
            }
            .foregroundColor(.secondary)
            
            // 1. 功能开关组
            VStack(spacing: 12) {
                Toggle(isOn: $windowManager.isInteractive) {
                    Label("投喂与互动模式", systemImage: "hand.tap.fill")
                }
                .toggleStyle(.switch)
                
                Toggle(isOn: $windowManager.isAudioEnabled) {
                    Label("环境与气泡音效", systemImage: "speaker.wave.2.fill")
                }
                .toggleStyle(.switch)
            }
            
            Divider()
            
            // 2. 🚀 背景切换 (全新加入)
            VStack(alignment: .leading, spacing: 8) {
                Label("场景背景", systemImage: "photo.on.rectangle.angled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // 使用分段选择器，非常有 macOS 控制中心的质感
                Picker("", selection: $windowManager.selectedBackground) {
                    ForEach(AquariumBackground.allCases, id: \.self) { bg in
                        Text(bg.rawValue).tag(bg)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Divider()
            
            // 3. 退出按钮
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "power")
                    Text("退出程序")
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(width: 260) // 稍微加宽一点，让 Segmented Picker 更好看
    }
}
