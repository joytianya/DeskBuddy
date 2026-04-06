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
    private var globalMouseMonitor: Any?
    private var settingsWindow: NSWindow?

    // 拖拽 & 双击检测
    private var dragStart: NSPoint = .zero
    private var isDragging = false
    private var lastClickTime: TimeInterval = 0

    // 鼠标速度追踪
    private var lastMousePos: NSPoint = .zero
    private var lastMouseTime: TimeInterval = 0

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
        setupGlobalMouseMonitor()
    }

    override init(window: NSWindow?) {
        self.petEngine = PetEngine(size: CGSize(width: 128, height: 128))
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let m = eventMonitor { NSEvent.removeMonitor(m) }
        if let m = globalMouseMonitor { NSEvent.removeMonitor(m) }
    }

    // MARK: - Local event monitor (click / drag / right-click)

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseUp, .rightMouseDown]
        ) { [weak self] event in
            guard let self, let window = self.window, event.window === window else { return event }
            switch event.type {
            case .leftMouseDown:
                self.dragStart = event.locationInWindow
                self.isDragging = false
            case .leftMouseUp:
                let dx = event.locationInWindow.x - self.dragStart.x
                let dy = event.locationInWindow.y - self.dragStart.y
                let dist = sqrt(dx*dx + dy*dy)
                if dist > 8 {
                    // 拖拽松手 → 翻滚
                    self.petEngine.onDropped()
                } else {
                    // 点击：检测双击
                    let now = Date().timeIntervalSinceReferenceDate
                    if now - self.lastClickTime < 0.35 {
                        self.petEngine.onDoubleClick()
                        self.lastClickTime = 0
                    } else {
                        self.lastClickTime = now
                        NotificationCenter.default.post(name: .toggleChat, object: nil)
                    }
                }
            case .rightMouseDown:
                self.showContextMenu(for: event)
            default:
                break
            }
            return event
        }
    }

    // MARK: - Global mouse monitor (proximity & speed)

    private func setupGlobalMouseMonitor() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged]
        ) { [weak self] event in
            self?.handleGlobalMouse(event)
        }
    }

    private func handleGlobalMouse(_ event: NSEvent) {
        guard let window = window else { return }
        let mouseScreen = NSEvent.mouseLocation
        let petCenter = NSPoint(x: window.frame.midX, y: window.frame.midY)

        let dx = mouseScreen.x - petCenter.x
        let dy = mouseScreen.y - petCenter.y
        let distance = sqrt(dx*dx + dy*dy)

        // 计算鼠标速度
        let now = Date().timeIntervalSinceReferenceDate
        let dt = now - lastMouseTime
        var speed: CGFloat = 0
        if dt > 0 && dt < 0.5 {
            let sdx = mouseScreen.x - lastMousePos.x
            let sdy = mouseScreen.y - lastMousePos.y
            speed = sqrt(sdx*sdx + sdy*sdy) / CGFloat(dt)
        }
        lastMousePos = mouseScreen
        lastMouseTime = now

        // 只在鼠标足够近时触发互动（< 150pt）
        if distance < 150 {
            petEngine.onMouseNear(distance: distance, mouseX: mouseScreen.x, speed: speed)
        }
    }

    // MARK: - Context menu

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
        if let w = settingsWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 560),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "设置"
        w.isReleasedWhenClosed = false
        let settings = AppSettings()
        w.contentView = NSHostingView(rootView: SettingsView(settings: settings, onDismiss: { [weak w] in
            w?.close()
        }))
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = w
    }
}
