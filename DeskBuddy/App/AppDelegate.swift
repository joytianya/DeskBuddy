// DeskBuddy/App/AppDelegate.swift
import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: PetWindowController?
    let emotionEngine = EmotionEngine()
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 单例检查：如果已有实例运行，激活它并退出当前实例
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier!)
        if runningApps.count > 1 {
            // 找到其他实例并激活
            for app in runningApps where app != NSRunningApplication.current {
                app.activate(options: [.activateIgnoringOtherApps])
                break
            }
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.accessory)
        windowController = PetWindowController(emotionEngine: emotionEngine)
        windowController?.showWindow(nil)
        // 状态绑定现在在PetWindowView内部处理
        emotionEngine.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
