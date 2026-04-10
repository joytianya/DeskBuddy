// DeskBuddy/Pet/AnimationRhythm.swift
import Foundation

/// 动画节奏规则：定义播放→停顿循环的参数
struct AnimationRhythm {
    let playDuration: TimeInterval    // 播放多久（秒）
    let pauseDuration: TimeInterval   // 停顿多久（秒）
    let frameInterval: TimeInterval   // 帧间隔（秒）
    let maxCycles: Int?               // nil = 无限循环，有限值 = 每轮播放次数上限

    static func forState(_ state: PetState) -> AnimationRhythm {
        switch state {
        case .idle:
            // idle 状态：跳跃动画，跳2次后停顿，不一直跳
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
            // excited 特殊处理：跳2次后停顿，不无限跳
            return AnimationRhythm(playDuration: 1.0, pauseDuration: 2.0, frameInterval: 0.12, maxCycles: 2)
        case .clingy:
            return AnimationRhythm(playDuration: 3.0, pauseDuration: 1.0, frameInterval: 0.18, maxCycles: nil)
        case .lying:
            // 趴着休息：很慢的动画，长时间停顿
            return AnimationRhythm(playDuration: 5.0, pauseDuration: 8.0, frameInterval: 0.50, maxCycles: nil)
        }
    }
}