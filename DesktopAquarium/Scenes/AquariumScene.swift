//
//  AquariumScene.swift
//  DesktopAquarium
//
//  Created by it on 2026/4/17.
//

import SpriteKit
import Combine
import AVFoundation // 🚀 【新增】：导入音频底层库

class AquariumScene: SKScene {
    private var lastUpdateTime: TimeInterval = 0
    private var backgroundNode: SKSpriteNode?
    private var cancellables = Set<AnyCancellable>()
    // 【新增】：环境音轨节点
    private var ambientPlayer: AVAudioPlayer?
    // 【新增】：记录当前鼠标悬停的坐标
    var currentMousePosition: CGPoint? = nil
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        self.backgroundColor = .clear
        self.scaleMode = .resizeFill
        
        // 🚀 1. 设置空间音频的“耳朵” (Listener)
        // 创建一个透明节点放在屏幕正中间，代表用户的头部
        let listenerNode = SKNode()
        self.addChild(listenerNode)
        self.listener = listenerNode
        
        // 🚀 2. 启动环境底噪
        setupAmbientAudio()
        
        // 监听背景变化
        WindowManager.shared.$selectedBackground
            .sink { [weak self] bg in
                self?.updateBackground(to: bg)
            }
            .store(in: &cancellables)
        
        // 🚀 【新增】：监听音频开关变化
        WindowManager.shared.$isAudioEnabled
            .sink { [weak self] isEnabled in
                self?.handleAudioToggle(isEnabled)
            }
            .store(in: &cancellables)
        
        let screenBounds = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
        
        // 投放 15 条绿鱼
        for _ in 0..<15 {
            let fish = FishNode(config: .greenFish)
            let safeMaxX = max(101, screenBounds.width - 100)
            let safeMaxY = max(101, screenBounds.height - 100)
            fish.position = CGPoint(x: CGFloat.random(in: 100...safeMaxX), y: CGFloat.random(in: 100...safeMaxY))
            self.addChild(fish)
        }
        
        // 【新增】：投放 10 条红鱼
        for _ in 0..<10 {
            let fish = FishNode(config: .redFish)
            let safeMaxX = max(101, screenBounds.width - 100)
            let safeMaxY = max(101, screenBounds.height - 100)
            fish.position = CGPoint(x: CGFloat.random(in: 100...safeMaxX), y: CGFloat.random(in: 100...safeMaxY))
            self.addChild(fish)
        }
        
        for _ in 0..<10 {
            let fish = FishNode(config: .yellowFish)
            let safeMaxX = max(101, screenBounds.width - 100)
            let safeMaxY = max(101, screenBounds.height - 100)
            fish.position = CGPoint(x: CGFloat.random(in: 100...safeMaxX), y: CGFloat.random(in: 100...safeMaxY))
            self.addChild(fish)
        }
        
        // 投放 2 条黄鱼
        for _ in 0..<2 {
            let fish = FishNode(config: .bigYellowFish)
            let safeMaxX = max(101, screenBounds.width - 100)
            let safeMaxY = max(101, screenBounds.height - 100)
            fish.position = CGPoint(x: CGFloat.random(in: 100...safeMaxX), y: CGFloat.random(in: 100...safeMaxY))
            self.addChild(fish)
        }
        
        for _ in 0..<1 {
            let fish = FishNode(config: .coloredFish1)
            let safeMaxX = max(101, screenBounds.width - 100)
            let safeMaxY = max(101, screenBounds.height - 100)
            fish.position = CGPoint(x: CGFloat.random(in: 100...safeMaxX), y: CGFloat.random(in: 100...safeMaxY))
            self.addChild(fish)
        }

        for _ in 0..<2 {
            let fish = FishNode(config: .coloredFish2)
            let safeMaxX = max(101, screenBounds.width - 100)
            let safeMaxY = max(101, screenBounds.height - 100)
            fish.position = CGPoint(x: CGFloat.random(in: 100...safeMaxX), y: CGFloat.random(in: 100...safeMaxY))
            self.addChild(fish)
        }

        
        // 【新增】：投放 1 条剑鱼（大鱼）
        let hunter = FishNode(config: .hunterFish)
        let safeMaxX = max(101, screenBounds.width - 100)
        let safeMaxY = max(101, screenBounds.height - 100)
        // 让大鱼随机出生在屏幕边缘区域，营造一种“游入视野”的感觉
        hunter.position = CGPoint(x: safeMaxX, y: CGFloat.random(in: 100...safeMaxY))
        self.addChild(hunter)
    }
    // 因为 listener 节点需要随着屏幕缩放保持居中，我们在 didChangeSize 中更新它
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        self.listener?.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
    }
    // MARK: - 音频系统
    private func setupAmbientAudio() {
        // 1. 获取音频文件的真实物理路径
        let bundle = Bundle(for: AquariumScene.self)
        guard let url = bundle.url(forResource: "ambient", withExtension: "mp3") else {
            print("⚠️ 找不到 ambient.mp3 文件！")
            return
        }
        
        do {
            // 2. 初始化播放器
            ambientPlayer = try AVAudioPlayer(contentsOf: url)
            
            // 3. 基础设置
            ambientPlayer?.numberOfLoops = -1 // -1 代表无限循环
            ambientPlayer?.volume = 0.0       // 初始音量设为 0
            
            // 4. 开始播放
            ambientPlayer?.play()
            
            // 5. 🚀 AVFoundation 原生支持的完美淡入效果！(1.5秒内音量过渡到 0.3)
            ambientPlayer?.setVolume(0.3, fadeDuration: 1.5)
            
            print("✅ 环境音轨启动成功！")
        } catch {
            print("⚠️ 环境音轨加载失败: \(error.localizedDescription)")
        }
    }
    
    private func updateBackground(to bg: AquariumBackground) {
        // 先移除旧背景
        backgroundNode?.removeFromParent()
        
        if bg == .none {
            backgroundNode = nil
            return
        }
        
        // 创建新背景（假设你有对应的图片资源）
        // 如果暂时没图，可以先用一个纯色块测试：SKTexture(rect: ..., color: .blue)
        let imgName: String
        switch bg {
        case .deepSea:
            imgName = "deepSea"
        case .coralReef:
            imgName = "coralReef"
        default:
            imgName = ""
        }
        let texture = SKTexture.safeLoad(name: imgName)
        let node = SKSpriteNode(texture: texture)
        
        node.zPosition = -100 // 确保在最底层
        node.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        
        // 自动适配屏幕尺寸 (Aspect Fill)
        let scaleX = self.frame.width / node.size.width
        let scaleY = self.frame.height / node.size.height
        let scale = max(scaleX, scaleY)
        node.setScale(scale)
        
        self.addChild(node)
        self.backgroundNode = node
    }
    // MARK: - 音频控制
    private func handleAudioToggle(_ isEnabled: Bool) {
        guard let player = ambientPlayer else { return }
        
        if isEnabled {
            // 开启：用 1 秒的时间将音量淡入到 0.3
            player.play()
            player.setVolume(0.3, fadeDuration: 1.0)
        } else {
            // 关闭：用 1 秒的时间淡出到 0 (丝滑静音)
            player.setVolume(0.0, fadeDuration: 1.0)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        let visibleBounds = self.frame
        
        // 收集当前场景里所有的鱼
        let flock = self.children.compactMap { $0 as? FishNode }
        
        // 让每条鱼在更新时感知到整个鱼群
        for fish in flock {
            fish.update(deltaTime: deltaTime, bounds: visibleBounds, flock: flock)
        }
    }
    
    // MARK: - 惊吓交互
    func updateMouseHover(at position: CGPoint?) {
        self.currentMousePosition = position
    }
    
    func dropFood(at position: CGPoint) {
        // 1. 画一个简单的圆形代表鱼食 (你也可以换成贴图)
        let food = SKShapeNode(circleOfRadius: 4.0)
        food.fillColor = NSColor(red: 0.8, green: 0.6, blue: 0.3, alpha: 1.0) // 褐色鱼食
        food.strokeColor = .white
        food.lineWidth = 1.0
        
        // 🚀 核心：打上标签，方便一会鱼去寻找它
        food.name = "fish_food"
        food.position = position
        food.zPosition = 50
        
        self.addChild(food)
        
        // 2. 物理掉落动画：慢慢沉到缸底
        let sinkDistance = position.y + 100 // 沉到屏幕外
        let sinkDuration = TimeInterval(sinkDistance / 60.0) // 匀速下沉
        
        let sink = SKAction.moveBy(x: 0, y: -sinkDistance, duration: sinkDuration)
        let remove = SKAction.removeFromParent()
        
        food.run(SKAction.sequence([sink, remove]))
    }
}
