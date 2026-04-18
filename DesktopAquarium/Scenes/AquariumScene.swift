//
//  AquariumScene.swift
//  DesktopAquarium
//
//  Created by it on 2026/4/17.
//

import SpriteKit

class AquariumScene: SKScene {
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        // 确保场景背景是透明的
        self.backgroundColor = .clear
        
        // 缩放模式设为填充
        self.scaleMode = .resizeFill
        
        // 阶段一调试：在屏幕中央放一个占位节点，确认渲染正常
        let testNode = SKShapeNode(circleOfRadius: 30)
        testNode.fillColor = .cyan
        testNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        self.addChild(testNode)
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // 当窗口缩放时，保证测试节点始终居中（后续鱼群逻辑会用到坐标更新）
        if let node = self.children.first {
            node.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        }
    }
}
