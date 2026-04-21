import ScreenSaver
import SpriteKit

@objc(AquariumSaverView)
class AquariumSaverView: ScreenSaverView {
    
    private var skView: SKView?
    private var isSceneSetup = false // 🚀 新增：标记是否已经初始化

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.animationTimeInterval = 1.0 / 60.0
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.animationTimeInterval = 1.0 / 60.0
    }
    
    // 🚀 终极修复 1：延迟加载。绝不在 init 里碰 UI！
    private func setupSpriteKitIfNeeded() {
        // 确保只初始化一次
        guard !isSceneSetup else { return }
        isSceneSetup = true
        
        let view = SKView(frame: self.bounds)
        view.autoresizingMask = [.width, .height]
        view.allowsTransparency = false
        view.ignoresSiblingOrder = true
        
        self.addSubview(view)
        self.skView = view
        
        let scene = AquariumScene(size: self.bounds.size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .black
        
        // 🚀 终极修复 2：彻底掐断音频引擎！防止底层音频冲突导致主线程黑屏掉帧
        WindowManager.shared.isAudioEnabled = false
        
        WindowManager.shared.isInteractive = false
        WindowManager.shared.selectedBackground = .deepSea
        
        view.presentScene(scene)
    }
    
    // MARK: - 屏保生命周期控制
    
    override func startAnimation() {
        super.startAnimation()
        
        // 🚀 在系统明确准备好播放动画时，才真正把鱼缸搬出来
        setupSpriteKitIfNeeded()
        skView?.isPaused = false
    }
    
    override func stopAnimation() {
        super.stopAnimation()
        skView?.isPaused = true
    }
    
    // 拦截系统绘制，绝不调用 super.draw(rect)
    override func draw(_ rect: NSRect) {
        // 保持留空
    }
    
    override func animateOneFrame() {
        return
    }
    
    override var hasConfigureSheet: Bool {
        return false
    }
    
    override var configureSheet: NSWindow? {
        return nil
    }
}
