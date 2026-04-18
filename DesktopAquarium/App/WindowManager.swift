import AppKit
import Combine

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    private weak var window: NSWindow?
    
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
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        // 4. 固定在桌面底层 (Icons 之下)
        window.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)))
        
        // 5. 默认开启点击穿透
        window.ignoresMouseEvents = true
    }
}
