// DeskBuddy/Window/PetWindowView.swift
import SwiftUI
import SpriteKit

struct PetWindowView: View {
    let engine: PetEngine
    @ObservedObject var emotionEngine: EmotionEngine
    @StateObject private var aiBridge = AIBridge()
    @StateObject private var settings = AppSettings()
    @State private var showSettings = false

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
                .colorMultiply(Color(hex: settings.petColorHex) ?? .white)
                .onAppear {
                    engine.setSkin(settings.selectedSkin)
                    engine.setPetScale(CGFloat(settings.petScale))
                }
                .onChange(of: settings.selectedSkin) { engine.setSkin($0) }
                .onChange(of: settings.petScale) { engine.setPetScale(CGFloat($0)) }
                .sheet(isPresented: $showSettings) {
                    SettingsView(settings: settings)
                }

            ChatBubbleView(aiBridge: aiBridge, emotionEngine: emotionEngine, voiceEnabled: settings.voiceEnabled)
        }
        .frame(width: 400, height: 400)
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            showSettings = true
        }
    }
}
