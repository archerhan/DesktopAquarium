import AppKit
import Combine

// 1. 定义显示模式枚举
enum DisplayMode: String, CaseIterable {
    case allSpaces = "所有桌面"
    case currentSpace = "当前桌面"
}

enum AquariumBackground: String, CaseIterable {
    case none = "无（透明桌面）"
    case deepSea = "深海蓝"
    case coralReef = "珊瑚礁"
    // 你可以后续增加更多背景图名称
}

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    private weak var window: NSWindow?
    // 【新增】：是否开启交互（投喂）模式
    @Published var isInteractive: Bool = false
    
    // 【新增】发布背景选择状态
    @Published var selectedBackground: AquariumBackground = .none
    
    // 【新增】：是否开启环境音，默认开启
    @Published var isAudioEnabled: Bool = true
    
    // 🚀 新增：用于存储 Combine 监听器的集合
    private var cancellables = Set<AnyCancellable>()
    
    // 2. 🚀 新增：显示模式状态
    @Published var displayMode: DisplayMode = .allSpaces {
        didSet {
            applyCollectionBehavior()
        }
    }
    
    // 🚀 新增：初始化方法
    private init() {
        setupSmartDeactivation()
    }
    
    // MARK: - 智能退让机制
    private func setupSmartDeactivation() {
        // 1. 监听用户切换虚拟桌面 (Spaces)
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.turnOffInteractiveIfNeeded(reason: "切换了桌面")
            }
            .store(in: &cancellables)
        
        // 2. 监听用户去操作了其他软件 (App 失去焦点)
        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.turnOffInteractiveIfNeeded(reason: "点击了其他软件")
            }
            .store(in: &cancellables)
    }
    
    private func turnOffInteractiveIfNeeded(reason: String) {
        if isInteractive {
            isInteractive = false
            print("🛑 智能退让触发 (\(reason))，自动退出投喂模式！")
        }
    }
    
    func setupWindow(_ window: NSWindow) {
        self.window = window
        
        // 1. 设置全屏尺寸 (覆盖主屏幕)
        if let screen = NSScreen.main {
            window.setFrame(screen.frame, display: true)
        }
        
        // 2. 关键属性：全透明、无边框
        window.styleMask = [.borderless, .fullSizeContentView]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        
        // 3. 层级与空间锁定
        // .canJoinAllSpaces: 在所有 Space (桌面) 都可见
        // .stationary: 窗口在切换窗口时不改变层级（固定在背景）
        // .ignoresCycle: 不出现在 Cmd+Tab 的切换循环中
        window.collectionBehavior = [.fullScreenAuxiliary, .ignoresCycle]
        // 4. 固定在桌面底层 (Icons 之下)
        window.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)))
        
        // 5. 默认开启点击穿透
        window.ignoresMouseEvents = true
        
        // 3. 🚀 初始化时应用收集行为
        applyCollectionBehavior()
    }
    
    // 4. 🚀 核心逻辑：动态切换窗口的系统行为
    private func applyCollectionBehavior() {
        guard let window = window else { return }
        
        if displayMode == .allSpaces {
            // 方案 A：在所有桌面可见，且在切换时保持静止（真正的动态壁纸感）
            window.collectionBehavior = [
                .canJoinAllSpaces,
                .stationary,
                .ignoresCycle,
                .fullScreenAuxiliary
            ]
        } else {
            // 方案 B：仅在当前桌面可见。
            // 💡 注意：这里去掉了 .stationary，这样切换桌面时鱼缸会跟着旧桌面一起滑走，避免产生残影
            window.collectionBehavior = [
                .ignoresCycle,
                .fullScreenAuxiliary
            ]
        }
    }
}
