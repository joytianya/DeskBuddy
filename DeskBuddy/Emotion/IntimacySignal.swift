// DeskBuddy/Emotion/IntimacySignal.swift
import Foundation

class IntimacySignal: ObservableObject {
    private let defaults: UserDefaults
    private let key = "intimacy_value"

    /// Use a custom UserDefaults suite for testability
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var rawValue: Double {
        get { defaults.double(forKey: key) }
        set { defaults.set(min(100, max(0, newValue)), forKey: key) }
    }

    var score: Double { rawValue / 100.0 }

    func recordChat() { rawValue += 2 }
    func recordClick() { rawValue += 1 }

    func tick(idleMinutes: Int) {
        if idleMinutes > 30 { rawValue -= 1 }
    }
}
