// DeskBuddy/Window/PetWindowController.swift
import AppKit
import SwiftUI
import Combine

extension Notification.Name {
    static let openSettings = Notification.Name("DeskBuddy.openSettings")
    static let toggleChat   = Notification.Name("DeskBuddy.toggleChat")
    static let hideChat     = Notification.Name("DeskBuddy.hideChat")
    static let resetWindowPosition = Notification.Name("DeskBuddy.resetWindowPosition")
}

private class PetPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// 当前活跃的渲染引擎引用（供外部访问）
class ActiveRenderEngine: ObservableObject {
    @Published var engine: PetRenderEngine?
}

class PetWindowController: NSWindowController {
    private var activeEngine = ActiveRenderEngine()
    private var eventMonitor: Any?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    // 拖拽 & 双击检测
    private var dragStart: NSPoint = .zero
    private var isDragging = false
    private var lastClickTime: TimeInterval = 0

    // 鼠标速度追踪
    private var lastMousePos: NSPoint = .zero
    private var lastMouseTime: TimeInterval = 0

    /// 计算窗口尺寸：2D模式128px基础，3D模式200px基础，乘以petScale
    private static func calculateWindowSize() -> CGFloat {
        let config = ConfigStore.shared
        let baseSize: CGFloat = config.renderMode == "3d" ? 200 : 128
        return baseSize * CGFloat(config.petScale)
    }

    convenience init(emotionEngine: EmotionEngine) {
        // 直接计算窗口尺寸（convenience init 中不能调用静态方法）
        let config = ConfigStore.shared
        let baseSize: CGFloat = config.renderMode == "3d" ? 200 : 128
        let windowSize = baseSize * CGFloat(config.petScale)

        let panel = PetPanel(
            contentRect: NSRect(x: config.windowX, y: config.windowY, width: windowSize, height: windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, NSWindow.CollectionBehavior.stationary]
        panel.isMovableByWindowBackground = true

        // 先调用init
        self.init(window: panel)

        // 然后创建petView并设置（使用已存在的activeEngine属性）
        let petView = PetWindowView(emotionEngine: emotionEngine, activeEngine: activeEngine)
        panel.contentView = NSHostingView(rootView: petView)

        setupEventMonitor()
        setupGlobalMouseMonitor()
        setupConfigListener()
        setupWindowPositionListener()
        setupResetPositionListener()
    }

    /// 监听重置窗口位置通知
    private func setupResetPositionListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResetWindowPosition),
            name: .resetWindowPosition,
            object: nil
        )
    }

    @objc private func handleResetWindowPosition() {
        guard let window = window else { return }
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowSize = Self.calculateWindowSize()
        let centerX = screenFrame.midX - windowSize / 2
        let centerY = screenFrame.midY - windowSize / 2
        let newFrame = NSRect(x: centerX, y: centerY, width: windowSize, height: windowSize)
        window.setFrame(newFrame, display: true)
    }

    /// 监听窗口移动，保存位置到 ConfigStore
    private func setupWindowPositionListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: window
        )
    }

    @objc private func windowDidMove() {
        guard let window = window else { return }
        ConfigStore.shared.windowX = window.frame.origin.x
        ConfigStore.shared.windowY = window.frame.origin.y
    }

    /// 监听配置变化，动态调整窗口尺寸
    private func setupConfigListener() {
        let config = ConfigStore.shared
        // 监听 petScale 和 renderMode 变化
        config.$petScale
            .combineLatest(config.$renderMode)
            .sink { [weak self] _ in
                self?.updateWindowSize()
            }
            .store(in: &cancellables)
    }

    /// 更新窗口尺寸
    private func updateWindowSize() {
        guard let window = window else { return }
        let newSize = Self.calculateWindowSize()
        let currentFrame = window.frame
        // 保持窗口中心位置不变
        let newFrame = NSRect(
            x: currentFrame.midX - newSize / 2,
            y: currentFrame.midY - newSize / 2,
            width: newSize,
            height: newSize
        )
        window.setFrame(newFrame, display: true)
    }

    override init(window: NSWindow?) {
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let m = eventMonitor { NSEvent.removeMonitor(m) }
        if let m = localMouseMonitor { NSEvent.removeMonitor(m) }
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
                guard let engine = self.activeEngine.engine else { return event }
                let dx = event.locationInWindow.x - self.dragStart.x
                let dy = event.locationInWindow.y - self.dragStart.y
                let dist = sqrt(dx*dx + dy*dy)
                if dist > 8 {
                    // 拖拽松手 → 翻滚
                    engine.onDropped()
                } else {
                    // 点击：检测双击
                    let now = Date().timeIntervalSinceReferenceDate
                    if now - self.lastClickTime < 0.35 {
                        engine.onDoubleClick()
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
        // 全局监控：监控其他应用的鼠标移动
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged]
        ) { [weak self] _ in
            self?.handleMouseProximity()
        }

        // 本地监控：监控本应用内的鼠标移动（补充全局监控的盲区）
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged]
        ) { [weak self] event in
            self?.handleMouseProximity()
            return event
        }

        // 全局点击监控：点击窗口外时隐藏聊天框
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            guard let window = self?.window else { return }
            let mouseLoc = NSEvent.mouseLocation
            // 如果点击不在窗口内，隐藏聊天框
            if !window.frame.contains(mouseLoc) {
                NotificationCenter.default.post(name: .hideChat, object: nil)
            }
        }
    }

    private func handleMouseProximity() {
        guard let window = window, let engine = activeEngine.engine else { return }
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
            engine.onMouseNear(distance: distance, mouseX: mouseScreen.x, speed: speed)
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
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "设置"
        w.isReleasedWhenClosed = false
        let settings = AppSettings()
        w.contentView = NSHostingView(rootView: SettingsView(settings: settings, onDismiss: { [weak w, weak self] in
            w?.close()
            self?.window?.orderFront(nil)
        }))
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = w
    }
}