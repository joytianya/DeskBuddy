// DeskBuddy/Window/PetWindowController.swift
import AppKit
import SwiftUI

class PetWindowController: NSWindowController {
    convenience init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 128, height: 128),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.contentView = NSHostingView(rootView: PetWindowView())
        self.init(window: panel)
        enableDrag()
    }

    private func enableDrag() {
        guard let panel = window else { return }
        panel.isMovableByWindowBackground = true
    }
}
