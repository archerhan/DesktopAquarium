import AppKit
import Combine
import SwiftUI

enum DisplayMode: String, CaseIterable {
    case allSpaces = "所有桌面"
    case currentSpace = "当前桌面"
}

enum AquariumBackground: String, CaseIterable {
    case none = "无（透明桌面）"
    case deepSea = "深海蓝"
    case coralReef = "珊瑚礁"
}

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    private var activeWindow: NSWindow?
    
    // 🚀 核心修复 1：废除所有的 didSet！只保留最纯粹的状态声明。
    @Published var selectedDisplayIndex: Int = 0
    @Published var isInteractive: Bool = false
    @Published var selectedBackground: AquariumBackground = .none
    @Published var isAudioEnabled: Bool = true
    @Published var displayMode: DisplayMode = .allSpaces
    
    // 🚀 新增：生态随机触发器。每次赋新值都会通知场景重新刷鱼
    @Published var ecologyRandomizer = UUID()
    
    // 🚀 新增：暴露给 UI 按钮调用的方法
    func randomizeEcology() {
        ecologyRandomizer = UUID()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupStateObservers()
        setupSystemListeners()
    }
    
    // MARK: - 🚀 状态变更监听 (防波堤)
    private func setupStateObservers() {
        // 使用 Combine 监听状态改变。
        // dropFirst() 避免初始化时触发；receive(on:) 确保在主线程且在当前视图更新周期【之后】执行。
        
        $selectedDisplayIndex
            .dropFirst()
            .removeDuplicates() // 只有值真改变了才执行
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.moveToSelectedScreen()
            }
            .store(in: &cancellables)
            
        $isInteractive
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] interactive in
                guard let window = self?.activeWindow else { return }
                window.ignoresMouseEvents = !interactive
                window.backgroundColor = interactive ? NSColor.black.withAlphaComponent(0.05) : .clear
                if interactive {
                    NSApp.activate(ignoringOtherApps: true)
                    window.orderFrontRegardless()
                }
            }
            .store(in: &cancellables)
            
        $displayMode
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyCollectionBehavior()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 🚀 系统通知监听 (防过载)
    private func setupSystemListeners() {
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            // 🚀 核心修复 2：加入 0.2 秒延迟！
            // 避开系统切换桌面的“高负载冰冻期”，完美防止音频引擎崩溃！
            .delay(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.turnOffInteractiveIfNeeded(reason: "切换了桌面")
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.turnOffInteractiveIfNeeded(reason: "点击了其他软件")
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            // 🚀 核心修复 3：加入防抖！
            // 忽略极短时间内系统发出的乱七八糟的屏幕重置通知，只在最终稳定时才平移窗口
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.moveToSelectedScreen()
            }
            .store(in: &cancellables)
    }
    
    private func turnOffInteractiveIfNeeded(reason: String) {
        if self.isInteractive {
            self.isInteractive = false
            print("🛑 智能退让触发 (\(reason))，自动退出投喂模式！")
        }
    }
    
    // MARK: - 单屏幕移动引擎
    func setupSingleWindow() {
        if activeWindow == nil {
            let screen = NSScreen.screens.first ?? NSScreen.main!
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)))
            window.ignoresMouseEvents = !isInteractive
            
            window.contentView = NSHostingView(rootView: ContentView())
            self.activeWindow = window
        }
        moveToSelectedScreen()
    }
    
    private func moveToSelectedScreen() {
        guard let window = activeWindow else { return }
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        
        let targetScreen: NSScreen
        if selectedDisplayIndex >= 0 && selectedDisplayIndex < screens.count {
            targetScreen = screens[selectedDisplayIndex]
        } else {
            targetScreen = screens[0]
            if self.selectedDisplayIndex != 0 {
                self.selectedDisplayIndex = 0 // 这个改变会被上方的 sink 捕获，但由于去重机制不会死循环
            }
        }
        
        // 🚀 核心修复 4：设置 display: false
        // 仅仅移动坐标，但不强制要求系统立刻重绘，彻底解决 LayoutRecursion 死锁
        window.setFrame(targetScreen.frame, display: false)
        
        applyCollectionBehavior()
        window.orderFront(nil)
    }
    
    private func applyCollectionBehavior() {
        guard let window = activeWindow else { return }
        if displayMode == .allSpaces {
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        } else {
            window.collectionBehavior = [.ignoresCycle, .fullScreenAuxiliary]
        }
    }
}
