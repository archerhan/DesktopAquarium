import SpriteKit

class FishNode: SKSpriteNode {
    let config: FishConfig
    var currentAngle: CGFloat = 0.0
    var velocity: CGVector = .zero
    // 【新增】：大鱼的狩猎冷却时间
    var huntCooldown: TimeInterval = 0
    // 【新增】：当前实际游速
    var currentSpeed: CGFloat = 0
    // 【新增】：每条鱼天生的逃窜偏好（向左偏或向右偏），用于打破圆弧阵型
    let panicEvasionDirection: CGFloat = Bool.random() ? 1.0 : -1.0
    
    init(config: FishConfig) {
        self.config = config
        self.currentSpeed = config.moveSpeed
        let texture = SKTexture(imageNamed: config.textureName)
        texture.filteringMode = .nearest
        super.init(texture: texture, color: .clear, size: texture.size())
        self.setScale(config.baseScale)
        self.currentAngle = CGFloat.random(in: 0...(2 * .pi))
//        startSwimmingAnimation()
        setupShader()
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
                    if minDistance < 50 {
                        huntCooldown = 4.0
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
                    
                    // 🚀【核心优化 2：斜向逃避 (V字炸开)】根据自身偏好，向左或向右呈最大 60 度角闪避
                    let currentEscapeAngle = atan2(survivalForce.dy, survivalForce.dx)
                    // 距离大鱼越近，炸开的角度越极端
                    let scatterIntensity = max(0, (120 - closestThreatDist) / 120)
                    // .pi / 3 就是 60度
                    let dartAngle = currentEscapeAngle + (panicEvasionDirection * (.pi / 3) * scatterIntensity)
                    
                    // 重新覆盖生存引导力，让小鱼斜着窜出去
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
        
        // 2. 行为优先级仲裁
        if isUnderThreat {
            // 处于生死关头：无视群游，全力转向（逃跑或追逐）
            let targetAngle = atan2(survivalForce.dy, survivalForce.dx)
            var angleDiff = targetAngle - currentAngle
            while angleDiff > .pi { angleDiff -= 2 * .pi }
            while angleDiff < -.pi { angleDiff += 2 * .pi }
            
            // 大鱼追击转身稍慢，小鱼逃命转身极快
            let reactionSpeed: CGFloat = config.isPredator ? 2.5 : 5.0
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
        
        // 5. 转向防抖 (解决垂直游动时的左右横跳)
        let flipThreshold: CGFloat = 1.5 // 设定一个横向速度阈值
        
        if velocity.dx > flipThreshold {
            // 明确向右游时，才向右翻转
            self.xScale = -abs(self.xScale)
        } else if velocity.dx < -flipThreshold {
            // 明确向左游时，才向左翻转
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
    }
}
