import Foundation
import CoreGraphics

struct FishConfig {
    let speciesName: String
    let textureName: String
    let moveSpeed: CGFloat
    let wanderRate: CGFloat
    let turnSpeed: CGFloat
    let baseScale: CGFloat
    let animationDuration: TimeInterval
    
    // --- 新增 Boids 属性 ---
    let perceptionRadius: CGFloat // 感知半径（鱼能看到多远的同伴）
    let separationRadius: CGFloat // 分离半径（靠多近会觉得“太挤了”并弹开）
    let separationWeight: CGFloat // 斥力权重（越大越不喜欢挤一起）
    let alignmentWeight: CGFloat  // 对齐权重（越大越随大流）
    let cohesionWeight: CGFloat   // 凝聚权重（越大越喜欢往鱼群中心钻）
    
    // --- 新增：生存与猎食属性 ---
    let isPredator: Bool       // 是否为捕食者
    let threatRadius: CGFloat  // 小鱼感知危险的距离（多远开始跑）
    let chaseRadius: CGFloat   // 大鱼锁定猎物的视野距离
    let huntCooldown: TimeInterval // 表示一次捕食行为结束后，需要休息多久才进行下一次捕食
    
    // --- 新增：着色器动画属性 ---
    let wagFrequency: Float // 波浪频率：决定鱼身同时呈现几个 S 型（越长的鱼数值越大）
    

}

extension FishConfig {
    
    // MARK: - 🦈 捕食者 (Predators)
    // 特点：孤独的猎手，体型巨大，视力极佳，平时巡游稳定，绝不扎堆
    
    static let predator1 = FishConfig(
        speciesName: "剑鱼",
        textureName: "h1",
        moveSpeed: 125.0,
        wanderRate: 0.6,
        turnSpeed: 1.2,
        baseScale: 0.3,
        animationDuration: 0.4,
        perceptionRadius: 0,
        separationRadius: 0,
        separationWeight: 0,
        alignmentWeight: 0,
        cohesionWeight: 0,
        isPredator: true,
        threatRadius: 0,
        chaseRadius: 400.0,
        huntCooldown: 20.0,
        wagFrequency: 8.0
    )
    
    static let predator2 = FishConfig(
        speciesName: "旗鱼",
        textureName: "h2",
        moveSpeed: 115.0,
        wanderRate: 0.8,
        turnSpeed: 1.5,
        baseScale: 0.4,
        animationDuration: 0.4,
        perceptionRadius: 0,
        separationRadius: 0,
        separationWeight: 0,
        alignmentWeight: 0,
        cohesionWeight: 0,
        isPredator: true,
        threatRadius: 0,
        chaseRadius: 350.0,
        huntCooldown: 15.0,
        wagFrequency: 9.0
    )
    
    // MARK: - 🐋 大鱼 (Large Fishes)
    // 特点：体型庞大，游速缓慢，转身迟钝，有一种深海的沉稳感
    
    static let largeFish1 = FishConfig(
        speciesName: "大海鲢",
        textureName: "l1",
        moveSpeed: 50.0,
        wanderRate: 0.9,
        turnSpeed: 0.8,
        baseScale: 0.24,
        animationDuration: 0.8,
        perceptionRadius: 150.0,
        separationRadius: 60.0,
        separationWeight: 3.0,
        alignmentWeight: 0.5,
        cohesionWeight: 0.8,
        isPredator: false,
        threatRadius: 150.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 8.5
    )
    
    static let largeFish2 = FishConfig(
        speciesName: "黄鳍金枪鱼",
        textureName: "l2",
        moveSpeed: 120.0,
        wanderRate: 1.1,
        turnSpeed: 1.9,
        baseScale: 0.4,
        animationDuration: 0.4,
        perceptionRadius: 120.0,
        separationRadius: 90.0,
        separationWeight: 8,
        alignmentWeight: 0.2,
        cohesionWeight: 0.3,
        isPredator: false,
        threatRadius: 130.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 8
    )
    
    static let largeFish3 = FishConfig(
        speciesName: "白鲟",
        textureName: "l3",
        moveSpeed: 80.0,
        wanderRate: 1.0,
        turnSpeed: 1.0,
        baseScale: 0.30,
        animationDuration: 0.7,
        perceptionRadius: 160.0,
        separationRadius: 55.0,
        separationWeight: 3.5,
        alignmentWeight: 0.8,
        cohesionWeight: 0.9,
        isPredator: false,
        threatRadius: 160.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 8.0
    )
    
    static let largeFish4 = FishConfig(
        speciesName: "鹦嘴鱼",
        textureName: "l4",
        moveSpeed: 60.0,
        wanderRate: 1.2,
        turnSpeed: 1.1,
        baseScale: 0.4,
        animationDuration: 0.65,
        perceptionRadius: 140.0,
        separationRadius: 45.0,
        separationWeight: 3.0,
        alignmentWeight: 0.6,
        cohesionWeight: 1.0,
        isPredator: false,
        threatRadius: 180.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 7.0
    )
    
    // MARK: - 🐡 中鱼 (Medium Fishes)
    // 特点：均衡型，适合构成水族馆的主要视觉群落，参数介于大小鱼之间
    
    static let mediumFish1 = FishConfig(
        speciesName: "红龙鱼",
        textureName: "m1",
        moveSpeed: 80.0,
        wanderRate: 1.5,
        turnSpeed: 2.0,
        baseScale: 0.24,
        animationDuration: 0.5,
        perceptionRadius: 120.0,
        separationRadius: 35.0,
        separationWeight: 4.0,
        alignmentWeight: 1.2,
        cohesionWeight: 1.2,
        isPredator: false,
        threatRadius: 220.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 6.0
    )
    
    static let mediumFish2 = FishConfig(
        speciesName: "梭子鱼",
        textureName: "m2",
        moveSpeed: 100.0,
        wanderRate: 1.6,
        turnSpeed: 2.2,
        baseScale: 0.3,
        animationDuration: 0.3,
        perceptionRadius: 110.0,
        separationRadius: 30.0,
        separationWeight: 4.5,
        alignmentWeight: 1.3,
        cohesionWeight: 1.1,
        isPredator: false,
        threatRadius: 230.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 7
    )
    
    static let mediumFish3 = FishConfig(
        speciesName: "公鸡鱼",
        textureName: "m3",
        moveSpeed: 50.0,
        wanderRate: 1.4,
        turnSpeed: 1.8,
        baseScale: 0.25,
        animationDuration: 0.55,
        perceptionRadius: 130.0,
        separationRadius: 40.0,
        separationWeight: 3.8,
        alignmentWeight: 1.0,
        cohesionWeight: 1.3,
        isPredator: false,
        threatRadius: 200.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 6.5
    )
    
    static let mediumFish4 = FishConfig(
        speciesName: "红鲑鱼",
        textureName: "m4",
        moveSpeed: 78.0,
        wanderRate: 1.7,
        turnSpeed: 2.3,
        baseScale: 0.46,
        animationDuration: 0.4,
        perceptionRadius: 100.0,
        separationRadius: 25.0,
        separationWeight: 5.0,
        alignmentWeight: 1.4,
        cohesionWeight: 1.4,
        isPredator: false,
        threatRadius: 240.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 5.5
    )
    
    static let mediumFish5 = FishConfig(
        speciesName: "丝帆鱼",
        textureName: "m5",
        moveSpeed: 82.0,
        wanderRate: 1.5,
        turnSpeed: 1.9,
        baseScale: 0.28,
        animationDuration: 0.48,
        perceptionRadius: 125.0,
        separationRadius: 38.0,
        separationWeight: 4.2,
        alignmentWeight: 1.1,
        cohesionWeight: 1.2,
        isPredator: false,
        threatRadius: 210.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 6.2
    )
    
    // MARK: - 🐟 小鱼 (Small Fishes)
    // 特点：游速最快，神经质（乱窜），极度抱团，稍微有捕食者靠近就疯狂逃窜
    
    static let smallFish1 = FishConfig(
        speciesName: "鬼头刀",
        textureName: "s1",
        moveSpeed: 110.0,
        wanderRate: 2.2,
        turnSpeed: 3.2,
        baseScale: 0.20,
        animationDuration: 0.25,
        perceptionRadius: 80.0,
        separationRadius: 20.0,
        separationWeight: 5.5,
        alignmentWeight: 1.8,
        cohesionWeight: 2.0,
        isPredator: false,
        threatRadius: 280.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 4.0
    )
    
    static let smallFish2 = FishConfig(
        speciesName: "加州金鲷",
        textureName: "s2",
        moveSpeed: 105.0,
        wanderRate: 2.5,
        turnSpeed: 3.5,
        baseScale: 0.24,
        animationDuration: 0.2,
        perceptionRadius: 75.0,
        separationRadius: 18.0,
        separationWeight: 6.0,
        alignmentWeight: 2.0,
        cohesionWeight: 1.8,
        isPredator: false,
        threatRadius: 290.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 3.8
    )
    
    static let smallFish3 = FishConfig(
        speciesName: "红点鲑",
        textureName: "s3",
        moveSpeed: 115.0,
        wanderRate: 2.0,
        turnSpeed: 3.0,
        baseScale: 0.22,
        animationDuration: 0.28,
        perceptionRadius: 90.0,
        separationRadius: 22.0,
        separationWeight: 5.0,
        alignmentWeight: 1.6,
        cohesionWeight: 2.2,
        isPredator: false,
        threatRadius: 270.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 4.2
    )
    
    static let smallFish4 = FishConfig(
        speciesName: "刺豚",
        textureName: "s4",
        moveSpeed: 120.0,
        wanderRate: 2.8,
        turnSpeed: 3.8,
        baseScale: 0.3,
        animationDuration: 0.18,
        perceptionRadius: 70.0,
        separationRadius: 15.0,
        separationWeight: 6.5,
        alignmentWeight: 2.2,
        cohesionWeight: 2.5,
        isPredator: false,
        threatRadius: 300.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 3.5
    )
    
    static let smallFish5 = FishConfig(
        speciesName: "蓝吊",
        textureName: "s5",
        moveSpeed: 108.0,
        wanderRate: 2.3,
        turnSpeed: 3.3,
        baseScale: 0.4,
        animationDuration: 0.22,
        perceptionRadius: 85.0,
        separationRadius: 19.0,
        separationWeight: 5.8,
        alignmentWeight: 1.9,
        cohesionWeight: 1.9,
        isPredator: false,
        threatRadius: 285.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 3.9
    )
    
    static let smallFish6 = FishConfig(
        speciesName: "孔雀鲈",
        textureName: "s6",
        moveSpeed: 100.0,
        wanderRate: 2.1,
        turnSpeed: 2.9,
        baseScale: 0.25,
        animationDuration: 0.3,
        perceptionRadius: 95.0,
        separationRadius: 25.0,
        separationWeight: 4.8,
        alignmentWeight: 1.5,
        cohesionWeight: 1.7,
        isPredator: false,
        threatRadius: 260.0,
        chaseRadius: 0,
        huntCooldown: 0,
        wagFrequency: 4.5
    )
    
    // MARK: - 🌍 生态图鉴库 (用于随机生成)
    static let allPredators = [predator1, predator2]
    static let allLarge = [largeFish1, largeFish2, largeFish3, largeFish4]
    static let allMedium = [mediumFish1, mediumFish2, mediumFish3, mediumFish4, mediumFish5]
    static let allSmall = [smallFish1, smallFish2, smallFish3, smallFish4, smallFish5, smallFish6]
}
