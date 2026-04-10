// DeskBuddy/Pet/AnimationRhythm.swift
import Foundation

/// 动画节奏规则：定义播放→停顿循环的参数
struct AnimationRhythm {
    let playDuration: TimeInterval    // 播放多久（秒）
    let pauseDuration: TimeInterval   // 停顿多久（秒）
    let frameInterval: TimeInterval   // 帧间隔（秒）
    let maxCycles: Int?               // nil = 无限循环，有限值 = 每轮播放次数上限

    /// 从 ConfigStore 读取配置，向后兼容无配置时使用默认值
    static func forState(_ state: PetState) -> AnimationRhythm {
        let config = ConfigStore.shared
        let key = stateName(for: state)

        // 尝试从配置读取
        if let rhythmConfig = config.animationRhythms[key] {
            return AnimationRhythm(
                playDuration: rhythmConfig.playDuration,
                pauseDuration: rhythmConfig.pauseDuration,
                frameInterval: rhythmConfig.frameInterval,
                maxCycles: rhythmConfig.maxCycles
            )
        }

        // fallback 默认值（兼容旧配置）
        return defaultRhythm(for: state)
    }

    /// 状态名映射（用于配置文件 key）
    private static func stateName(for state: PetState) -> String {
        switch state {
        case .idle: return "idle"
        case .happy: return "happy"
        case .sleepy: return "sleepy"
        case .anxious: return "anxious"
        case .bored: return "bored"
        case .excited: return "excited"
        case .clingy: return "clingy"
        case .lying: return "lying"
        }
    }

    /// 默认动画节奏（硬编码 fallback）
    private static func defaultRhythm(for state: PetState) -> AnimationRhythm {
        switch state {
        case .idle:
            return AnimationRhythm(playDuration: 1.0, pauseDuration: 3.0, frameInterval: 0.15, maxCycles: 2)
        case .happy:
            return AnimationRhythm(playDuration: 1.5, pauseDuration: 2.5, frameInterval: 0.15, maxCycles: nil)
        case .sleepy:
            return AnimationRhythm(playDuration: 4.0, pauseDuration: 1.0, frameInterval: 0.30, maxCycles: nil)
        case .anxious:
            return AnimationRhythm(playDuration: 0.8, pauseDuration: 0.5, frameInterval: 0.10, maxCycles: nil)
        case .bored:
            return AnimationRhythm(playDuration: 1.0, pauseDuration: 4.0, frameInterval: 0.25, maxCycles: nil)
        case .excited:
            return AnimationRhythm(playDuration: 1.0, pauseDuration: 2.0, frameInterval: 0.12, maxCycles: 2)
        case .clingy:
            return AnimationRhythm(playDuration: 3.0, pauseDuration: 1.0, frameInterval: 0.18, maxCycles: nil)
        case .lying:
            return AnimationRhythm(playDuration: 5.0, pauseDuration: 8.0, frameInterval: 0.50, maxCycles: nil)
        }
    }
}