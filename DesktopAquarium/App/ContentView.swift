import SwiftUI
import SpriteKit
import AppKit

// MARK: - 原生事件与窗口拦截器
struct EventInterceptView: NSViewRepresentable {
    @Binding var isInteractive: Bool
    var onClick: (CGPoint) -> Void
    var onHover: (CGPoint?) -> Void
    
    func makeNSView(context: Context) -> InterceptNSView {
        let view = InterceptNSView()
        view.onClick = onClick
        view.onHover = onHover
        return view
    }
    
    func updateNSView(_ nsView: InterceptNSView, context: Context) {
        nsView.isInteractive = isInteractive
        // 🚀 终极防死锁：这里绝对不触碰 nsView.window!
        // 彻底切断 SwiftUI 布局循环和 AppKit 窗口渲染的冲突
    }
}

class InterceptNSView: NSView {
    var isInteractive: Bool = false
    var onClick: ((CGPoint) -> Void)?
    var onHover: ((CGPoint?) -> Void)?
    
    private var trackingArea: NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            self.removeTrackingArea(trackingArea)
        }
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeAlways]
        trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }
    
    override func mouseMoved(with event: NSEvent) {
        if isInteractive {
            let location = self.convert(event.locationInWindow, from: nil)
            onHover?(location)
        }
    }
    
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
