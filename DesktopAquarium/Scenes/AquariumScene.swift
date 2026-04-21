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
        
        // 🚀 监听 WindowManager 的随机指令
        WindowManager.shared.$ecologyRandomizer
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.generateRandomEcology()
            }
            .store(in: &cancellables)
        
    }
    
    // MARK: - 🎲 核心随机生成算法
    private func generateRandomEcology() {
        print("🌊 开始重新生成海洋生态...")
        
        // 1. 清理旧生态：移除所有旧的鱼节点和数组记录
        self.children.filter { $0 is FishNode }.forEach { $0.removeFromParent() }
        // 如果你的代码里有专门存鱼的数组（用于 Boids 计算），也需要清空，比如：
        // self.fishes.removeAll()
        
        // 2. 🦈 生成 1 只捕食者
        if let predator = FishConfig.allPredators.randomElement() {
            spawnFishes(config: predator, count: 1)
        }
        
        // 3. 🐋 随机挑选 2 种大鱼，每种生成 1~2 条
        let selectedLarge = FishConfig.allLarge.shuffled().prefix(2)
        for config in selectedLarge {
            spawnFishes(config: config, count: Int.random(in: 1...2))
        }
        
        // 4. 🐡 随机挑选 3 种中鱼，每种生成 3~5 条
        let selectedMedium = FishConfig.allMedium.shuffled().prefix(3)
        for config in selectedMedium {
            spawnFishes(config: config, count: Int.random(in: 3...5))
        }
        
        // 5. 🐟 随机挑选 2 种小鱼，每种生成 10~15 条（形成极具观赏性的鱼群）
        let selectedSmall = FishConfig.allSmall.shuffled().prefix(2)
        for config in selectedSmall {
            spawnFishes(config: config, count: Int.random(in: 10...15))
        }
    }
    
    // 辅助生成的提取方法
    // 辅助生成的提取方法
    private func spawnFishes(config: FishConfig, count: Int) {
        for _ in 0..<count {
            let fish = FishNode(config: config)
            
            // 在屏幕范围内随机找一个出生点
            let randomX = CGFloat.random(in: 0...max(self.size.width, 100))
            let randomY = CGFloat.random(in: 0...max(self.size.height, 100))
            fish.position = CGPoint(x: randomX, y: randomY)
            
            // 🚀 核心修复：移除 360 度随机旋转，改为强制水平 + 随机左右朝向
            fish.zRotation = 0 // 初始绝对水平
            
            let isFacingLeft = Bool.random() // 抛硬币决定初始朝左还是朝右
            // 通过 xScale 的正负值来做镜像翻转 (假设素材默认朝左)
            fish.xScale = isFacingLeft ? abs(config.baseScale) : -abs(config.baseScale)
            
            // 💡 可选优化：如果你在 FishNode 里维护了速度向量 (velocity)
            // 最好也在这里给它一个初始的水平初速度，避免它刚出生时原地发呆或乱窜
            /*
            let initialSpeed = config.moveSpeed * 0.5
            let dx = isFacingLeft ? -initialSpeed : initialSpeed
            fish.velocity = CGVector(dx: dx, dy: CGFloat.random(in: -10...10))
            */
            
            // 赋予随机深浅层级，增加 3D 景深感
            fish.zPosition = CGFloat.random(in: -50...50)
            
            self.addChild(fish)
            // 记得加进你的 Boids 数组中，比如： self.fishes.append(fish)
        }
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
