// DeskBuddy/Window/PetWindowController.swift
import AppKit
import SwiftUI

extension Notification.Name {
    static let openSettings = Notification.Name("DeskBuddy.openSettings")
    static let toggleChat   = Notification.Name("DeskBuddy.toggleChat")
}

private class PetPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

class PetWindowController: NSWindowController {
    private(set) var petEngine: PetEngine
    private var eventMonitor: Any?

    convenience init(emotionEngine: EmotionEngine) {
        let panel = PetPanel(
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
        panel.isMovableByWindowBackground = true

        let petView = PetWindowView(emotionEngine: emotionEngine)
        panel.contentView = NSHostingView(rootView: petView)
        self.init(window: panel)
        self.petEngine = petView.engine
        setupEventMonitor()
    }

    override init(window: NSWindow?) {
        self.petEngine = PetEngine(size: CGSize(width: 128, height: 128))
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let monitor = eventMonitor { NSEvent.removeMonitor(monitor) }
    }

    private func setupEventMonitor() {
        var dragStart: NSPoint = .zero

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .rightMouseDown]) { [weak self] event in
            guard let self, let window = self.window, event.window === window else { return event }

            switch event.type {
            case .leftMouseDown:
                dragStart = event.locationInWindow
            case .leftMouseUp:
                let dx = event.locationInWindow.x - dragStart.x
                let dy = event.locationInWindow.y - dragStart.y
                if sqrt(dx*dx + dy*dy) < 5 {
                    NotificationCenter.default.post(name: .toggleChat, object: nil)
                }
            case .rightMouseDown:
                self.showContextMenu(for: event)
            default:
                break
            }
            return event
        }
    }

    private func showContextMenu(for event: NSEvent) {
        let menu = NSMenu()
        menu.addItem(withTitle: "设置", action: #selector(openSettings), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        if let view = window?.contentView {
            NSMenu.popUpContextMenu(menu, with: event, for: view)
        }
    }

    @objc private func openSettings() {
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }
}
