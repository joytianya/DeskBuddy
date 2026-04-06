// DeskBuddy/Window/PetWindowView.swift
import SwiftUI
import SpriteKit

struct PetWindowView: View {
    let engine: PetEngine
    @ObservedObject var emotionEngine: EmotionEngine
    @ObservedObject private var config = ConfigStore.shared
    @StateObject private var aiBridge = AIBridge()

    init(emotionEngine: EmotionEngine) {
        let scene = PetEngine(size: CGSize(width: 128, height: 128))
        scene.scaleMode = .aspectFit
        self.engine = scene
        self._emotionEngine = ObservedObject(wrappedValue: emotionEngine)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SpriteView(scene: engine, options: [.allowsTransparency])
                .frame(width: 128, height: 128)
                .background(Color.clear)
                .colorMultiply(Color(hex: config.petColorHex) ?? .white)
                .onAppear {
                    engine.setSkin(config.selectedSkin)
                    engine.setPetScale(CGFloat(config.petScale))
                }
                .onChange(of: config.selectedSkin) { engine.setSkin($0) }
                .onChange(of: config.petScale) { engine.setPetScale(CGFloat($0)) }

            ChatBubbleView(aiBridge: aiBridge, emotionEngine: emotionEngine, voiceEnabled: config.voiceEnabled)
        }
        .frame(width: 400, height: 400)
    }
}
