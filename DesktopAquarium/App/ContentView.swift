import SwiftUI
import SpriteKit
import AppKit

// MARK: - 原生事件与窗口拦截器
struct EventInterceptView: NSViewRepresentable {
    @Binding var isInteractive: Bool
    var onClick: (CGPoint) -> Void
    var onHover: (CGPoint?) -> Void // 🚀 新增：鼠标滑动轨迹回调
    
    func makeNSView(context: Context) -> InterceptNSView {
        let view = InterceptNSView()
        view.onClick = onClick
        view.onHover = onHover
        return view
    }
    
    func updateNSView(_ nsView: InterceptNSView, context: Context) {
        nsView.isInteractive = isInteractive
        
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.ignoresMouseEvents = !isInteractive
                window.backgroundColor = isInteractive ? NSColor.black.withAlphaComponent(0.05) : .clear
                if isInteractive {
                    NSApp.activate(ignoringOtherApps: true)
                    window.orderFrontRegardless()
                }
            }
        }
    }
}

class InterceptNSView: NSView {
    var isInteractive: Bool = false
    var onClick: ((CGPoint) -> Void)?
    var onHover: ((CGPoint?) -> Void)? // 🚀 记录滑动闭包
    
    private var trackingArea: NSTrackingArea?
    
    // 🚀 核心升级 1：安装鼠标追踪雷达
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            self.removeTrackingArea(trackingArea)
        }
        // 配置雷达：监听鼠标移动、进入退出，且永远激活
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeAlways]
        trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }
    
    // 🚀 核心升级 2：上报鼠标移动坐标 (原点对齐 SpriteKit)
    override func mouseMoved(with event: NSEvent) {
        if isInteractive {
            let location = self.convert(event.locationInWindow, from: nil)
            onHover?(location)
        }
    }
    
    // 🚀 核心升级 3：鼠标离开窗口时，解除惊吓状态
    override func mouseExited(with event: NSEvent) {
        onHover?(nil)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { return true }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return isInteractive ? self : nil
    }
    
    override func mouseDown(with event: NSEvent) {
        if isInteractive {
            let location = self.convert(event.locationInWindow, from: nil)
            onClick?(location)
        }
    }
}

// MARK: - 主视图
struct ContentView: View {
    @State private var scene: AquariumScene = {
        let s = AquariumScene()
        s.scaleMode = .resizeFill
        return s
    }()
    
    @ObservedObject var windowManager = WindowManager.shared

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.allowsTransparency])
            
            // 🚀 核心升级 4：接收 Hover 回调并传给场景
            EventInterceptView(
                isInteractive: $windowManager.isInteractive,
                onClick: { location in
                    scene.dropFood(at: location)
                },
                onHover: { location in
                    scene.updateMouseHover(at: location)
                }
            )
        }
        .ignoresSafeArea()
        .frame(minWidth: 400, minHeight: 300)
    }
}
