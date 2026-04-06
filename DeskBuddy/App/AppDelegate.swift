// DeskBuddy/App/AppDelegate.swift
import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: PetWindowController?
    let emotionEngine = EmotionEngine()
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        windowController = PetWindowController(emotionEngine: emotionEngine)
        windowController?.showWindow(nil)
        emotionEngine.$currentState
            .sink { [weak self] state in
                self?.windowController?.petEngine.stateSubject.send(state)
            }
            .store(in: &cancellables)
        emotionEngine.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
