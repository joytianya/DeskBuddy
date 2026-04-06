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
            self?.intimacy.tick(idleMinutes: SystemSignal.currentIdleMinutes())
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

        // 检查系统空闲时间，长时间空闲时趴着休息
        let idleMinutes = SystemSignal.currentIdleMinutes()
        if idleMinutes > 3 {
            return .lying
        }

        // 新阈值分布（更平滑）
        switch combined {
        case 0.80...:  return .excited
        case 0.60...: return .happy
        case 0.45...: return .idle
        case 0.30...: return .bored
        case 0.15...: return .sleepy
        default:      return .anxious
        }
    }
}
