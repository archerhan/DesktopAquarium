//
//  ContentView.swift
//  DesktopAquarium
//
//  Created by it on 2026/4/17.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    // 实例化我们的场景
    var scene: SKScene {
        let scene = AquariumScene()
        return scene
    }

    var body: some View {
        // 开启 allowsTransparency 非常关键，否则无法透出背后的桌面
        SpriteView(scene: scene, options: [.allowsTransparency])
            .ignoresSafeArea()
            // 按照计划中的“执行贴士”，先给一个极淡的背景色方便调试窗口范围
            .background(Color.blue.opacity(0.1))
            .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
}
