import SpriteKit

class FishNode: SKSpriteNode {
    let config: FishConfig
    var currentAngle: CGFloat = 0.0
    var velocity: CGVector = .zero
    // 【新增】：大鱼的狩猎冷却时间
    var huntCooldown: TimeInterval = 0
    // 【新增】：当前实际游速
    var currentSpeed: CGFloat = 0
    // 记录存活时间，加上随机初始值防止所有鱼的 S 曲线神光同步
    var timeAlive: TimeInterval = Double.random(in: 0...100)
    
    // 【新增】：气泡粒子发射器
    private var bubbleEmitter: SKEmitterNode?
    
    // 【新增】：记录是否正在发力冲刺，防止音效重叠播放
    private var isDashing: Bool = false
    

    
    init(config: FishConfig) {
        self.config = config
        self.currentSpeed = config.moveSpeed
        let texture = SKTexture.safeLoad(name: config.textureName)
        texture.filteringMode = .nearest
        super.init(texture: texture, color: .clear, size: texture.size())
        self.setScale(config.baseScale)
        self.currentAngle = CGFloat.random(in: 0...(2 * .pi))
        setupShader()
        setupBubbles() // 初始化气泡
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    // MARK: - 流体扭曲着色器 (Shader)
    private func setupShader() {
        let shaderString = """
        void main() {
            vec2 uv = v_tex_coord;
            
            // 1. 确定锚点权重 (Anchor Weight)
            // 假设你的素材鱼头在左(x=0)，鱼尾在右(x=1)。
            // 使用 pow(uv.x, 2.5) 会让前半段身体(头和躯干)几乎不动，
            // 越靠近尾巴，柔软度和形变幅度越大，这非常符合鱼类的发力习惯。
            float wagMultiplier = pow(uv.x, 2.5) * 0.06; 
            
            // 2. 计算正弦波 (Sine Wave)
            float timePhase = u_time * u_speed;
            float wave = sin((uv.x * u_frequency) - timePhase);
            
            // 3. 【核心修正】：透视形变
            // 将主波浪应用在 X 轴上！尾巴的拉伸和挤压会产生“向内/向外摆动”的 3D 透视错觉。
            // Y 轴只保留极其微弱的扰动(0.1倍)，模拟身体发力时的自然微颤。
            vec2 offset = vec2(wave * wagMultiplier, wave * wagMultiplier * 0.1);
            
            gl_FragColor = texture2D(u_texture, uv + offset);
        }
        """
        
        let shader = SKShader(source: shaderString)
        
        // 传入初始 Uniform 变量
        shader.uniforms = [
            SKUniform(name: "u_frequency", float: config.wagFrequency),
            SKUniform(name: "u_speed", float: 5.0)
        ]
        
        self.shader = shader
    }
    
    // MARK: - 激流气泡特效
    private func setupBubbles() {
        let size = CGSize(width: 12, height: 12)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.withAlphaComponent(0.7).setFill()
        NSBezierPath(ovalIn: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        let bubbleTexture = SKTexture(image: image)
        
        let emitter = SKEmitterNode()
        emitter.particleTexture = bubbleTexture
        emitter.particleBirthRate = 0
        
        // 发射器位置放在尾巴尖端
        emitter.position = CGPoint(x: self.size.width * 0.4, y: 0)
        
        // 🚀 【核心区分】：根据是不是大鱼，分配完全不同的物理参数！
        let isBig = config.isPredator
        
        // 1. 寿命：大鱼的气泡能在水里残留很久 (2秒+)，小鱼的瞬间溶解 (0.6秒)
        emitter.particleLifetime = isBig ? 1.6 : 0.6
        emitter.particleLifetimeRange = isBig ? 1.0 : 0.3
        
        // 2. 尺寸：大鱼产生巨大的气雾团，小鱼只有微小的碎泡
        emitter.particleScale = isBig ? 0.2 : 0.1
        emitter.particleScaleRange = isBig ? 0.2 : 0.08
        emitter.particleScaleSpeed = isBig ? -0.3 : -0.4 // 小鱼气泡缩水消失得更快
        
        // 3. 喷射力度：大鱼尾巴甩水力量极大，小鱼甩水力量小
        emitter.particleSpeed = isBig ? 120.0 : 40.0
        emitter.particleSpeedRange = isBig ? 80.0 : 20.0
        
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi / 2.5
        
        // 4. 浮力扰动：大鱼搅动的水域更大
        emitter.yAcceleration = isBig ? 200.0 : 120.0
        emitter.particlePositionRange = CGVector(dx: isBig ? 25 : 8, dy: isBig ? 25 : 8)
        
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.5
        
        self.addChild(emitter)
        self.bubbleEmitter = emitter
    }
    
    // MARK: - 空间音频播放
    private func playDashSound() {
        guard WindowManager.shared.isAudioEnabled else { return }
        // 创建一个音效节点 (请确保项目中有 bubble.wav 或类似文件)
        let soundNode = SKAudioNode(fileNamed: "bubble.mp3")
        
        // 🚀 开启空间定位！
        // SpriteKit 会自动根据这只鱼相对于屏幕中心的 X/Y 坐标，计算左/右耳的音量大小和延迟
        soundNode.isPositional = true
        soundNode.autoplayLooped = false // 只播放一次
        
        // 大鱼的声音可以调大一点，小鱼声音清脆微弱一点
        let volume: Float = config.isPredator ? 0.3 : 0.2
        soundNode.run(SKAction.changeVolume(to: volume, duration: 0))
        
        self.addChild(soundNode)
        
        // 播放完毕后，自动将节点从内存中移除
        let play = SKAction.play()
        let wait = SKAction.wait(forDuration: 1.5) // 预估音效长度，稍长一点无妨
        let remove = SKAction.removeFromParent()
        soundNode.run(SKAction.sequence([play, wait, remove]))
    }

    // MARK: - Boids 核心算法
    private func calculateBoidsInfluence(flock: [FishNode]) -> CGVector {
        var separation = CGVector.zero
        var alignment = CGVector.zero
        var cohesion = CGPoint.zero
        
        var flockCount = 0       // 同类数量 (用于对齐和凝聚)
        var separationCount = 0  // 邻居数量 (包含异类，用于分离)
        
        for other in flock {
            // 不跟自己算，也不跟捕食者算群游
            if other === self || other.config.isPredator { continue }
            
            let dx = self.position.x - other.position.x
            let dy = self.position.y - other.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            // 如果对方在视野范围内
            if distance < config.perceptionRadius {
                
                // 🚀【修改点 1：无差别分离】不管是不是同类，只要是小鱼靠太近，都要产生斥力防止重叠
                if distance < config.separationRadius && distance > 0 {
                    separation.dx += (dx / distance) / distance
                    separation.dy += (dy / distance) / distance
                    separationCount += 1
                }
                
                // 🚀【修改点 2：物种隔离】只有名字相同（同类），才进行对齐和凝聚！
                if other.config.speciesName == self.config.speciesName {
                    flockCount += 1
                    
                    alignment.dx += other.velocity.dx
                    alignment.dy += other.velocity.dy
                    
                    cohesion.x += other.position.x
                    cohesion.y += other.position.y
                }
            }
        }
        
        var steer = CGVector.zero
        
        // 计算同类的引导力 (凝聚+对齐)
        if flockCount > 0 {
            alignment.dx = (alignment.dx / CGFloat(flockCount)) * config.alignmentWeight
            alignment.dy = (alignment.dy / CGFloat(flockCount)) * config.alignmentWeight
            
            cohesion.x /= CGFloat(flockCount)
            cohesion.y /= CGFloat(flockCount)
            let cohesionVector = CGVector(dx: cohesion.x - self.position.x, dy: cohesion.y - self.position.y)
            
            steer.dx += alignment.dx + (cohesionVector.dx * config.cohesionWeight)
            steer.dy += alignment.dy + (cohesionVector.dy * config.cohesionWeight)
        }
        
        // 计算所有小鱼产生的排斥力
        if separationCount > 0 {
            separation.dx = (separation.dx / CGFloat(separationCount)) * config.separationWeight
            steer.dx += separation.dx * 100
            steer.dy += separation.dy * 100
        }
        
        return steer
    }
    
    // MARK: - 更新逻辑
    // 注意：这里的参数增加了 flock 数组，让鱼能感知到其他鱼
    func update(deltaTime: TimeInterval, bounds: CGRect, flock: [FishNode]) {
        // 在 update 方法的最开始，让时间流动起来
        timeAlive += deltaTime
        // 【关键】：让吐出的气泡留在场景中，而不是跟着鱼跑
        if bubbleEmitter?.targetNode == nil {
            bubbleEmitter?.targetNode = self.scene
        }
        // 1. 漫步逻辑 (Wander)
        let randomSteer = CGFloat.random(in: -1...1) * config.wanderRate * CGFloat(deltaTime)
        currentAngle += randomSteer
        var targetSpeed: CGFloat = config.moveSpeed // 默认目标速度为基础速度

        // --- 生存与捕猎逻辑 ---
        var survivalForce = CGVector.zero
        var isUnderThreat = false
        
        if config.isPredator {
            // 【新增】：如果处于疲劳冷却期，扣减时间，并跳过追猎逻辑（恢复普通漫步）
            if huntCooldown > 0 {
                huntCooldown -= deltaTime
                // 【状态：疲劳】贤者时间，游得极其慢（40% 速度）
                targetSpeed = config.moveSpeed * 0.4
            } else {
                // 大鱼逻辑：寻找视野内最近的猎物
                var closestPrey: FishNode?
                var minDistance = config.chaseRadius
                
                for other in flock where !other.config.isPredator {
                    let dx = other.position.x - self.position.x
                    let dy = other.position.y - self.position.y
                    let distance = sqrt(dx*dx + dy*dy)
                    
                    if distance < minDistance {
                        minDistance = distance
                        closestPrey = other
                    }
                }
                
                if let prey = closestPrey {
                    if minDistance < 70 {
                        // 【状态：撕咬/吞咽结算】
                        // 1. 使用 config 中配置好的冷却时间，而不是硬编码的 4.0
                        huntCooldown = config.huntCooldown > 0 ? config.huntCooldown : 8.0
                        
                        // 2. 保持冲刺的极限速度甚至更高一点，模拟扑咬时的最终发力惯性
                        targetSpeed = config.moveSpeed * 3.0
                        
                        // 3. （可选）如果你有吃鱼逻辑，可以在这里把 prey 从场景中移除
                        // prey.removeFromParent()
                        // 并且播放一个吞咽或水花音效
                        
                    } else if minDistance < 150 {
                        // 【状态：猛扑】猎物近在咫尺，爆发出 2.5 倍的速度冲刺！
                        targetSpeed = config.moveSpeed * 2.5
                        let dx = prey.position.x - self.position.x
                        let dy = prey.position.y - self.position.y
                        survivalForce = CGVector(dx: dx / minDistance, dy: dy / minDistance)
                        isUnderThreat = true
                    } else {
                        // 【状态：靠近】锁定了远处的猎物，比平时游得快一点（1.2 倍速度）
                        targetSpeed = config.moveSpeed * 1.2
                        let dx = prey.position.x - self.position.x
                        let dy = prey.position.y - self.position.y
                        survivalForce = CGVector(dx: dx / minDistance, dy: dy / minDistance)
                        isUnderThreat = true
                    }
                } else {
                    // 【状态：巡逻】视野内没猎物，慢悠悠地游（60% 速度）
                    targetSpeed = config.moveSpeed * 0.6
                }
            }
            
        } else {
            // 小鱼逻辑：感知大鱼
            var closestThreatDist: CGFloat = .greatestFiniteMagnitude
            for other in flock where other.config.isPredator {
                let dx = self.position.x - other.position.x
                let dy = self.position.y - other.position.y
                let distance = sqrt(dx*dx + dy*dy)
                
                if distance < config.threatRadius {
                    closestThreatDist = min(closestThreatDist, distance)
                    let panicFactor = config.threatRadius / max(distance, 1.0)
                    survivalForce.dx += (dx / distance) * panicFactor
                    survivalForce.dy += (dy / distance) * panicFactor
                    isUnderThreat = true
                }
            }
            // 🚀 2. 【新增：干饭逻辑】(只有在没被大鱼追杀时才有心情吃饭)
            var closestFood: SKNode?
            var minFoodDist: CGFloat = 300.0 // 鱼的视力范围，能看到 300 像素内的食物
            if !isUnderThreat, let scene = self.scene {
                // 扫描场景里所有打上了 "fish_food" 标签的节点
                for node in scene.children where node.name == "fish_food" {
                    let dx = node.position.x - self.position.x
                    let dy = node.position.y - self.position.y
                    let dist = sqrt(dx*dx + dy*dy)
                    
                    if dist < minFoodDist {
                        minFoodDist = dist
                        closestFood = node
                    }
                }
                
                // 如果发现了食物
                if let food = closestFood {
                    if minFoodDist < 20 {
                        // 距离小于 20 像素，吃掉它！
                        food.removeFromParent()
                        // 吃饱了，原地吧唧一下嘴（短暂停顿减速）
                        targetSpeed = config.moveSpeed * 0.1
                        // 可以选择加上一点缩放动画模拟“吞咽”
                        let gulp = SKAction.sequence([
                            SKAction.scale(to: config.baseScale * 1.2, duration: 0.1),
                            SKAction.scale(to: config.baseScale, duration: 0.1)
                        ])
                        self.run(gulp)
                    } else {
                        // 【状态：抢食】爆发出 2.5 倍速冲向食物！
                        targetSpeed = config.moveSpeed * 2.5
                        let dx = food.position.x - self.position.x
                        let dy = food.position.y - self.position.y
                        
                        // 覆盖生存引导力，强制指向食物
                        survivalForce = CGVector(dx: dx / minFoodDist, dy: dy / minFoodDist)
                        // 复用威胁标记，这会直接打破 Boids 群游秩序，强行抢夺最高转向控制权！
                        isUnderThreat = true
                    }
                }
            }
            
            if isUnderThreat {
                if closestThreatDist < 120 {
                    // 【状态：惊恐】大鱼快贴脸了，以 2 倍速爆发逃生！
                    targetSpeed = config.moveSpeed * 2.0
                    
                    // 🚀【核心优化 1：恐慌斥力】在惊恐状态下，猛烈推开周围的同伴，防止挤成一团
                    for other in flock where !other.config.isPredator && other !== self {
                        let dx = self.position.x - other.position.x
                        let dy = self.position.y - other.position.y
                        let dist = sqrt(dx*dx + dy*dy)
                        if dist < 80 { // 靠得越近，推得越开
                            // 给生存力叠加一个极强的同类互斥力
                            survivalForce.dx += (dx / dist) * 3.0
                            survivalForce.dy += (dy / dist) * 3.0
                        }
                    }
                    
                    // 🚀【核心优化 2：S型蛇皮走位 (Serpentine Evasion)】
                    let currentEscapeAngle = atan2(survivalForce.dy, survivalForce.dx)
                    let scatterIntensity = max(0, (120 - closestThreatDist) / 120)
                    
                    // 利用正弦波 sin() 产生左右交替的摇摆角度。
                    // 乘数 12.0 控制扭屁股的频率，.pi/3.5 控制摇摆的幅度
                    let wiggleAngle = CGFloat(sin(timeAlive * 12.0)) * (.pi / 3.5) * scatterIntensity
                    let dartAngle = currentEscapeAngle + wiggleAngle
                    
                    survivalForce = CGVector(dx: cos(dartAngle), dy: sin(dartAngle))
                    
                } else {
                    // 【状态：警觉】感觉到危险，开始提速脱离（1.3 倍速度）
                    targetSpeed = config.moveSpeed * 1.3
                }
            } else {
                // 【状态：安全】恢复正常结伴群游
                targetSpeed = config.moveSpeed
            }
        }
        
        // 🚀 【新增：上帝之手（鼠标惊吓）】
        // 任何鱼（不论大小），只要靠近鼠标 150 像素内，就会吓得魂飞魄散
        if let scene = self.scene as? AquariumScene, let mousePos = scene.currentMousePosition {
            let dx = self.position.x - mousePos.x
            let dy = self.position.y - mousePos.y
            let dist = sqrt(dx*dx + dy*dy)
            
            if dist < 150 {
                isUnderThreat = true
                // 吓得半死，爆发出 3.5 倍的极致极限速度！
                targetSpeed = config.moveSpeed * 3.5
                // 逃命方向：严格背对鼠标坐标
                survivalForce = CGVector(dx: dx / dist, dy: dy / dist)
                
                // 如果是大鱼被吓到了，强制进入漫长的打断冷却，防止它继续吃鱼
                if config.isPredator {
                    huntCooldown = 2.0
                }
            }
        }
        
        // 2. 行为优先级仲裁
        if isUnderThreat {
            // 处于生死关头：无视群游，全力转向（逃跑或追逐）
            let targetAngle = atan2(survivalForce.dy, survivalForce.dx)
            var angleDiff = targetAngle - currentAngle
            while angleDiff > .pi { angleDiff -= 2 * .pi }
            while angleDiff < -.pi { angleDiff += 2 * .pi }
            
            // 大鱼追击转身稍慢，小鱼逃命转身极快
            let reactionSpeed: CGFloat = config.isPredator ? 1.2 : 6.0
            currentAngle += angleDiff * reactionSpeed * CGFloat(deltaTime)
            
        } else if !config.isPredator {
            // 安全状态下的小鱼：恢复 Boids 群游秩序
            let boidsForce = calculateBoidsInfluence(flock: flock)
            if boidsForce.dx != 0 || boidsForce.dy != 0 {
                let boidsAngle = atan2(boidsForce.dy, boidsForce.dx)
                var angleDiff = boidsAngle - currentAngle
                while angleDiff > .pi { angleDiff -= 2 * .pi }
                while angleDiff < -.pi { angleDiff += 2 * .pi }
                
                let boidsTurnSpeed: CGFloat = 0.6
                currentAngle += angleDiff * boidsTurnSpeed * CGFloat(deltaTime)
            }
        }

        // 3. 软边缘避让 (最高优先级)
        let margin: CGFloat = 120.0
        var avoidVector = CGVector.zero
        if self.position.x < bounds.minX + margin { avoidVector.dx = 1 }
        else if self.position.x > bounds.maxX - margin { avoidVector.dx = -1 }
        if self.position.y < bounds.minY + margin { avoidVector.dy = 1 }
        else if self.position.y > bounds.maxY - margin { avoidVector.dy = -1 }
        
        if avoidVector.dx != 0 || avoidVector.dy != 0 {
            let targetAngle = atan2(avoidVector.dy, avoidVector.dx)
            var angleDiff = targetAngle - currentAngle
            while angleDiff > .pi { angleDiff -= 2 * .pi }
            while angleDiff < -.pi { angleDiff += 2 * .pi }
            currentAngle += angleDiff * config.turnSpeed * CGFloat(deltaTime)
        }
        
        // --- 【关键：平滑加速度 (Lerp)】 ---
        // 模拟肌肉发力，让当前速度慢慢逼近目标速度，而不是瞬间切换
        let accelerationRate: CGFloat = config.isPredator ? 3.0 : 5.0 // 小鱼提速比大鱼快
        currentSpeed += (targetSpeed - currentSpeed) * accelerationRate * CGFloat(deltaTime)
        
        // 4. 计算最终速度和位置
        velocity.dx = cos(currentAngle) * currentSpeed
        velocity.dy = sin(currentAngle) * currentSpeed
        self.position.x += velocity.dx * CGFloat(deltaTime)
        self.position.y += velocity.dy * CGFloat(deltaTime)
        
        // 专门对付高速冲刺时软边界拉不住的情况，相当于给鱼缸加了实体玻璃
        let padding: CGFloat = 30.0 // 允许鱼身体稍微出界一点点边缘，但不完全消失
        var hitWall = false
        
        if self.position.x < bounds.minX - padding {
            self.position.x = bounds.minX - padding
            velocity.dx = abs(velocity.dx) // 撞左墙，强制向右弹
            hitWall = true
        } else if self.position.x > bounds.maxX + padding {
            self.position.x = bounds.maxX + padding
            velocity.dx = -abs(velocity.dx) // 撞右墙，强制向左弹
            hitWall = true
        }
        
        if self.position.y < bounds.minY - padding {
            self.position.y = bounds.minY - padding
            velocity.dy = abs(velocity.dy) // 撞底，强制向上弹
            hitWall = true
        } else if self.position.y > bounds.maxY + padding {
            self.position.y = bounds.maxY + padding
            velocity.dy = -abs(velocity.dy) // 撞顶，强制向下弹
            hitWall = true
        }
        
        // 如果触发了物理反弹，必须同步修正它的游动意图(角度)，否则下一帧它还会想往墙外游
        if hitWall {
            currentAngle = atan2(velocity.dy, velocity.dx)
        }
        
        // 5. 转向防抖 (终极修复版：解决鬼畜，同时消除倒着游)
        // 删除了引发 Bug 的“垂直锁定”，纯粹依赖“动态死区 (Deadzone)”
        
        // 动态死区：游速越快，允许的横向滑动误差越大 (约占当前速度的 6%)
        let flipDeadzone = max(1.5, currentSpeed * 0.06)
        
        // 只有当横向速度实打实地突破了死区，才进行翻转
        if velocity.dx > flipDeadzone {
            // 明确向右游
            self.xScale = -abs(self.xScale)
        } else if velocity.dx < -flipDeadzone {
            // 明确向左游
            self.xScale = abs(self.xScale)
        }
        
        
        // 注意：如果 velocity.dx 在 -1.5 到 1.5 之间，代码什么都不做，
        // 鱼就会平滑地保持它翻转前的朝向，完美消除鬼畜！
        // --- 【新增：同步摆尾动画速度】 ---
        // 将当前的物理游速 currentSpeed 映射给 Shader 中的 u_speed
        // --- 【优化：非线性同步摆尾动画速度】 ---
        if let speedUniform = self.shader?.uniformNamed("u_speed") {
            // 1. 降低基础映射比例 (从 12.0 改为 18.0)，让平时游动更显慵懒优雅
            let mappedSpeed = Float(targetSpeed / 18.0)
            
            // 2. 设定摆尾频率的“绝对上限” (比如 12.0)
            // 这样无论鱼冲刺得多快，尾巴都不会变成高频马达
            let maxTailSpeed: Float = 10.0
            
            // 3. 取两者中的较小值 (Clamp 限制)
            let finalAnimationSpeed = min(mappedSpeed, maxTailSpeed)
            
            speedUniform.floatValue = finalAnimationSpeed
        }
        // --- 【新增：速度激增引发多重气泡尾迹】 ---
        let bubbleThreshold = config.moveSpeed * 1.5
        
        // 🚀 根据鱼的种类，动态设定气泡生成倍率和衰减速度
        // 大鱼爆发量极大 (x4.0)，且衰减慢 (-8.0)；小鱼爆发量小 (x1.0)，且瞬间停歇 (-30.0)
        let birthRateMultiplier: CGFloat = config.isPredator ? 2.0 : 1.0
        let decayRate: CGFloat = config.isPredator ? 10.0 : 30.0
        
        if currentSpeed > bubbleThreshold {
            let extraSpeed = currentSpeed - bubbleThreshold
            // 速度超出极限越多，乘以专属倍率，喷出对应规模的气泡！
            bubbleEmitter?.particleBirthRate = extraSpeed * birthRateMultiplier
            // 🚀 【核心新增：触发空间音效】
            if !isDashing && extraSpeed > 20.0 { // 速度有明显的激增才发声
                isDashing = true
                playDashSound()
            }
        } else {
            // 速度降下来，重置冲刺状态
            isDashing = false
            // 平滑衰减模拟水流余波
            if let currentRate = bubbleEmitter?.particleBirthRate, currentRate > 0 {
                bubbleEmitter?.particleBirthRate = max(0, currentRate - decayRate)
            }
        }
    }
}
