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
        if idleMinutes > 10 {
            // 系统空闲超过 10 分钟 → lying（趴着或前爪着地）
            // 根据情绪分数决定具体姿态
            return .lying
        }

        // 新阈值分布（更平滑）
        switch combined {
        case 0.80...:  return .excited   // 很高兴（跳）
        case 0.60...: return .happy      // 开心
        case 0.45...: return .idle       // 正常
        case 0.30...: return .bored      // 无聊
        case 0.15...: return .sleepy     // 困倦
        default:      return .anxious    // 紧张（系统压力大）
        }
    }

    /// 获取 lying 状态的具体姿态：根据情绪分数决定趴着或前爪着地
    func getLyingVariant() -> Int {
        // 6 = Sleep（趴着），7 = Paw（前爪着地）
        // 情绪分数高 → 更活跃 → 前爪着地
        // 情绪分数低 → 更懒散 → 趴着
        let t = TimeSignal.currentScore()
        let i = intimacy.score
        let s = SystemSignal.score(
            cpuUsage: SystemSignal.currentCPUUsage(),
            memoryPressure: SystemSignal.currentMemoryPressure(),
            idleMinutes: SystemSignal.currentIdleMinutes()
        )
        let combined = t * 0.3 + i * 0.4 + s * 0.3

        // 情绪分数 > 0.5 → 30% 前爪着地，70% 趴着
        // 情绪分数 <= 0.5 → 10% 前爪着地，90% 趴着
        if combined > 0.5 {
            return Int.random(in: 0..<10) < 3 ? 7 : 6
        } else {
            return Int.random(in: 0..<10) < 1 ? 7 : 6
        }
    }
}
