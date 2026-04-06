// DeskBuddy/Window/PetWindowView.swift
import SwiftUI
import SpriteKit

struct PetWindowView: View {
    let engine: PetEngine
    @ObservedObject var emotionEngine: EmotionEngine
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

            ChatBubbleView(aiBridge: aiBridge, emotionEngine: emotionEngine)
        }
        .frame(width: 400, height: 400)
    }
}
