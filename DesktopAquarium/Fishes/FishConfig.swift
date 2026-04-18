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
    
    // --- 新增：着色器动画属性 ---
    let wagFrequency: Float // 波浪频率：决定鱼身同时呈现几个 S 型（越长的鱼数值越大）
}

extension FishConfig {
    static let greenFish = FishConfig(
        speciesName: "绿鱼",
        textureName: "green_fish",
        moveSpeed: 85.0,
        wanderRate: 1.8,
        turnSpeed: 2.2,
        baseScale: 0.3,
        animationDuration: 0.4,
        
        // 绿鱼的群游性格参数：
        perceptionRadius: 150.0,
        separationRadius: 40.0,
        separationWeight: 5, // 斥力设大一点，避免图片重叠
        alignmentWeight: 1.0,
        cohesionWeight: 0.8,
        
        isPredator: false,
        threatRadius: 200.0, // 在 200 像素外就能感知到大鱼并开始逃跑
        chaseRadius: 0,
        
        wagFrequency: 6.0 // 小鱼身体短，波浪频次适中
    )
    
    // 新增：红鱼（另一种猎物）配置
    static let redFish = FishConfig(
        speciesName: "红鱼", // 关键：名称不同，Boids 就会将它们隔离
        textureName: "red_fish", // 请记得在 Assets 里随便放一张名为 red_fish 的图片做测试
        moveSpeed: 100.0,    // 比绿鱼游得稍微快一点
        wanderRate: 1.5,
        turnSpeed: 2.8,      // 转身比绿鱼更灵活
        baseScale: 0.25,     // 体型略小
        animationDuration: 0.3, // 摆尾频率更快
        
        // 红鱼的群游性格：感知范围小，但非常抱团
        perceptionRadius: 100.0,
        separationRadius: 30.0,
        separationWeight: 4.0,
        alignmentWeight: 1.5,   // 更喜欢对齐
        cohesionWeight: 1.2,    // 凝聚力更强
        
        isPredator: false,
        threatRadius: 220.0, // 胆子小，大鱼在更远的地方就会开始跑
        chaseRadius: 0,
        
        wagFrequency: 6.0 // 小鱼身体短，波浪频次适中

    )
    
    // 新增：黄鱼（另一种猎物）配置
    static let yellowFish = FishConfig(
        speciesName: "黄鱼", // 关键：名称不同，Boids 就会将它们隔离
        textureName: "fish2",
        moveSpeed: 80.0,    // 比绿鱼游得稍微快一点
        wanderRate: 1.3,
        turnSpeed: 1.0,      // 转身比绿鱼更灵活
        baseScale: 0.5,     // 体型略小
        animationDuration: 0.5, // 摆尾频率更快
        
        // 红鱼的群游性格：感知范围小，但非常抱团
        perceptionRadius: 100.0,
        separationRadius: 30.0,
        separationWeight: 4.0,
        alignmentWeight: 0.4,   // 更喜欢对齐
        cohesionWeight: 1.5,    // 凝聚力更强
        
        isPredator: false,
        threatRadius: 220.0, // 胆子小，大鱼在更远的地方就会开始跑
        chaseRadius: 0,
        
        wagFrequency: 8.0
    )
    
    // 剑鱼（捕食者）配置
    static let hunterFish = FishConfig(
        speciesName: "剑鱼",
        textureName: "hunter_fish",
        moveSpeed: 130.0,      // 爆发速度比小鱼快
        wanderRate: 0.5,       // 目标明确，平时漫步幅度小
        turnSpeed: 1.2,        // 体型大，转身比小鱼稍显迟钝（给小鱼逃跑的机会）
        baseScale: 0.4,        // 根据你的原图大小，可能需要在这里缩放一下
        animationDuration: 0.4,// 摆尾频率稍慢，显得沉稳
        
        perceptionRadius: 0,   // 独行侠，不需要群游参数
        separationRadius: 0,
        separationWeight: 0,
        alignmentWeight: 0,
        cohesionWeight: 0,
        
        isPredator: true,
        threatRadius: 0,
        chaseRadius: 350.0,     // 视力极佳，能大范围锁定猎物
        
        wagFrequency: 8.0 // 剑鱼身体修长硬朗，S型波浪较少
    )
}
