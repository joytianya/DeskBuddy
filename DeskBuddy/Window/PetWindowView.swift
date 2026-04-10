// DeskBuddy/Window/PetWindowView.swift
import SwiftUI
import SpriteKit
import SceneKit
import Combine

struct PetWindowView: View {
    @ObservedObject var emotionEngine: EmotionEngine
    @ObservedObject private var config = ConfigStore.shared
    @ObservedObject var activeEngine: ActiveRenderEngine
    @StateObject private var aiBridge = AIBridge()

    // 引擎容器 - 符合ObservableObject
    @StateObject private var sceneKitContainer = SceneKitContainer()
    @StateObject private var spriteKitContainer = SpriteKitContainer()
    @State private var cancellables = Set<AnyCancellable>()

    /// 计算基础尺寸：2D模式128px，3D模式200px
    private var baseSize: CGFloat {
        config.renderMode == "3d" ? 200 : 128
    }

    /// 计算窗口尺寸：基础尺寸 × petScale
    private var windowSize: CGFloat {
        baseSize * CGFloat(config.petScale)
    }

    init(emotionEngine: EmotionEngine, activeEngine: ActiveRenderEngine) {
        self._emotionEngine = ObservedObject(wrappedValue: emotionEngine)
        self._activeEngine = ObservedObject(wrappedValue: activeEngine)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // 根据渲染模式选择显示
            if config.renderMode == "3d" {
                SceneView(
                    scene: sceneKitContainer.scene,
                    options: [.autoenablesDefaultLighting]
                )
                .frame(width: baseSize, height: baseSize)
                .background(Color.clear)
                .onAppear {
                    bindEmotionToEngine(sceneKitContainer.scene)
                    sceneKitContainer.scene.setPetScale(CGFloat(config.petScale))
                    activeEngine.engine = sceneKitContainer.scene
                }
                .onChange(of: config.petScale) { sceneKitContainer.scene.setPetScale(CGFloat($0)) }
                .onChange(of: config.petColorHex) { hex in
                    if let color = NSColor(hex: hex),
                       let dogNode = sceneKitContainer.scene.rootNode.childNode(withName: "dog", recursively: true) {
                        Dog3DModel.setDogColor(dogNode, color: color)
                    }
                }
            } else {
                SpriteView(scene: spriteKitContainer.scene, options: [.allowsTransparency])
                    .frame(width: baseSize, height: baseSize)
                    .background(Color.clear)
                    .colorMultiply(Color(hex: config.petColorHex) ?? .white)
                    .onAppear {
                        bindEmotionToEngine(spriteKitContainer.scene)
                        spriteKitContainer.scene.setSkin(config.selectedSkin)
                        spriteKitContainer.scene.setPetScale(CGFloat(config.petScale))
                        activeEngine.engine = spriteKitContainer.scene
                    }
                    .onChange(of: config.selectedSkin) { spriteKitContainer.scene.setSkin($0) }
                    .onChange(of: config.petScale) { spriteKitContainer.scene.setPetScale(CGFloat($0)) }
            }

            ChatBubbleView(aiBridge: aiBridge, emotionEngine: emotionEngine, voiceEnabled: config.voiceEnabled)
        }
        .frame(width: windowSize, height: windowSize)
    }

    private func bindEmotionToEngine(_ engine: PetRenderEngine) {
        emotionEngine.$currentState
            .sink { state in
                engine.stateSubject.send(state)
            }
            .store(in: &cancellables)
    }
}

// MARK: - 引擎容器类

/// SceneKit引擎容器 - 符合ObservableObject
class SceneKitContainer: ObservableObject {
    let scene: SceneKitEngine
    init() {
        scene = SceneKitEngine()
    }
}

/// SpriteKit引擎容器 - 符合ObservableObject
class SpriteKitContainer: ObservableObject {
    let scene: SpriteKitEngine
    init() {
        scene = SpriteKitEngine(size: CGSize(width: 128, height: 128))
        scene.scaleMode = .aspectFit
    }
}

// MARK: - NSColor hex扩展
extension NSColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}