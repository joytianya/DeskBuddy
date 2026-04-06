// DeskBuddy/Window/PetWindowController.swift
import AppKit
import SwiftUI

class PetWindowController: NSWindowController {
    private(set) var petEngine: PetEngine

    convenience init(emotionEngine: EmotionEngine) {
        let panel = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 400, height: 400),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        let view = PetWindowView(emotionEngine: emotionEngine)
        panel.contentView = NSHostingView(rootView: view)
        self.init(window: panel)
        self.petEngine = view.engine
        enableDrag()
    }

    override init(window: NSWindow?) {
        self.petEngine = PetEngine(size: CGSize(width: 128, height: 128))
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func enableDrag() {
        window?.isMovableByWindowBackground = true
    }
}
