//
//  AquariumScene.swift
//  DesktopAquarium
//
//  Created by it on 2026/4/17.
//

import SpriteKit

class AquariumScene: SKScene {
    private var lastUpdateTime: TimeInterval = 0
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        self.backgroundColor = .clear
        self.scaleMode = .resizeFill
        
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
        // 投放 2 条黄鱼
        for _ in 0..<2 {
            let fish = FishNode(config: .yellowFish)
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
}
