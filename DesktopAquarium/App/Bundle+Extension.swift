import SpriteKit

// 🚀 终极资源加载扩展：解决屏保模式下找不到资源的问题
extension SKTexture {
    static func safeLoad(name: String) -> SKTexture {
        // 强行获取我们自己代码所在的真实 Bundle，而不是系统的 Bundle.main
        let bundle = Bundle(for: AquariumScene.self)
        
        // 尝试从我们的 Bundle 中提取图片
        if let image = bundle.image(forResource: NSImage.Name(name)) {
            return SKTexture(image: image)
        }
        // 兜底方案
        return SKTexture(imageNamed: name)
    }
}
