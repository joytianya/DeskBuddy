// DeskBuddy/Emotion/EmotionEngine.swift
import Foundation
import Combine

class EmotionEngine: ObservableObject {
    @Published private(set) var currentState: PetState = .idle

    private let intimacy: IntimacySignal
    private var timer: Timer?

    init(intimacy: IntimacySignal = IntimacySignal()) {
        self.intimacy = intimacy
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.update()
        }
        update()
    }

    func stop() { timer?.invalidate() }

    func recordChat() { intimacy.recordChat(); update() }
    func recordClick() { intimacy.recordClick(); update() }

    private func update() {
        let t = TimeSignal.currentScore()
        let i = intimacy.score
        let s = SystemSignal.score(
            cpuUsage: SystemSignal.currentCPUUsage(),
            memoryPressure: SystemSignal.currentMemoryPressure(),
            idleMinutes: SystemSignal.currentIdleMinutes()
        )
        currentState = computeState(timeScore: t, intimacyScore: i, systemScore: s)
    }

    func computeState(timeScore: Double, intimacyScore: Double, systemScore: Double) -> PetState {
        let combined = timeScore * 0.3 + intimacyScore * 0.4 + systemScore * 0.3
        switch combined {
        case 0.85...:  return .excited
        case 0.65...: return .happy
        case 0.5...:  return .idle
        case 0.35...: return .bored
        case 0.2...:  return .sleepy
        default:      return .anxious
        }
    }
}
