import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        // 关掉系统默认窗口
        if let defaultWindow = NSApplication.shared.windows.first {
            defaultWindow.close()
        }
        
        // 🚀 启动单屏移动引擎
        WindowManager.shared.setupSingleWindow()
        
        setupStatusBar()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "fish", accessibilityDescription: "水族馆")
            button.action = #selector(togglePopover(_:))
        }
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 420)
        popover.behavior = .transient
        
        popover.contentViewController = NSHostingController(rootView: ModernControlPanelView())
        
        // 🚀 核心修复 1：监听 App 失去焦点（比如切换桌面、点击了其他软件的主窗口）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(forceClosePopover),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    @objc private func forceClosePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }
}

// MARK: - 现代控制面板 UI (SwiftUI)
struct ModernControlPanelView: View {
    @ObservedObject var windowManager = WindowManager.shared
    
    // 🚀 终极修复方案：异步绑定生成器 (The Async Clutch)
    // 截获所有的 UI 点击事件，强行推迟到下一个主线程周期执行
    // 彻底斩断 SwiftUI 视图刷新与 AppKit 底层系统响应的同步冲突！
    private func asyncBind<T>(_ keyPath: ReferenceWritableKeyPath<WindowManager, T>) -> Binding<T> {
        Binding(
            get: { self.windowManager[keyPath: keyPath] },
            set: { newValue in
                DispatchQueue.main.async {
                    self.windowManager[keyPath: keyPath] = newValue
                }
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "fish.fill")
                Text("水族馆控制台")
                    .font(.headline)
            }
            .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                // 🚀 所有控件不再直接绑定 $windowManager.xxx，而是使用 asyncBind
                Toggle(isOn: asyncBind(\.isInteractive)) {
                    Label("投喂与互动模式", systemImage: "hand.tap.fill")
                }
                .toggleStyle(.switch)
                
                Toggle(isOn: asyncBind(\.isAudioEnabled)) {
                    Label("环境与气泡音效", systemImage: "speaker.wave.2.fill")
                }
                .toggleStyle(.switch)
            }
            
            Divider()
            
            // 所在显示器设置
            VStack(alignment: .leading, spacing: 8) {
                Label("所在显示器", systemImage: "desktopcomputer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: asyncBind(\.selectedDisplayIndex)) {
                    ForEach(0..<NSScreen.screens.count, id: \.self) { index in
                        Text(NSScreen.screens[index].localizedName).tag(index)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // 桌面范围设置
            VStack(alignment: .leading, spacing: 8) {
                Label("桌面范围", systemImage: "macwindow.on.rectangle")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: asyncBind(\.displayMode)) {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // 背景切换
            VStack(alignment: .leading, spacing: 8) {
                Label("场景背景", systemImage: "photo.on.rectangle.angled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: asyncBind(\.selectedBackground)) {
                    ForEach(AquariumBackground.allCases, id: \.self) { bg in
                        Text(bg.rawValue).tag(bg)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Divider()
                        
            // 🚀 新增：生态随机重置按钮
            Button(action: {
                windowManager.randomizeEcology()
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "dice.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("随机重置生态")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.vertical, 8)
                // 使用极其温柔的蓝色背景，与警示的红色退出按钮形成区分
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Divider()
            
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
        .frame(width: 260)
    }
}
