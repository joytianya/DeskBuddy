// DeskBuddyTests/EmotionEngineTests.swift
import XCTest
@testable import DeskBuddy

final class EmotionEngineTests: XCTestCase {

    // MARK: - TimeSignal

    func test_timeSignal_morning_returnsLow() {
        XCTAssertLessThan(TimeSignal.score(hour: 7), 0.4)
    }

    func test_timeSignal_midday_returnsHigh() {
        XCTAssertGreaterThan(TimeSignal.score(hour: 10), 0.7)
    }

    func test_timeSignal_lateNight_returnsVeryLow() {
        XCTAssertLessThan(TimeSignal.score(hour: 3), 0.2)
    }

    // MARK: - SystemSignal

    func test_systemSignal_highCPU_returnsLow() {
        let score = SystemSignal.score(cpuUsage: 0.85, memoryPressure: 0.3, idleMinutes: 5)
        XCTAssertLessThan(score, 0.3)
    }

    func test_systemSignal_idle_returnsLow() {
        let score = SystemSignal.score(cpuUsage: 0.1, memoryPressure: 0.1, idleMinutes: 50)
        XCTAssertLessThan(score, 0.4)
    }

    func test_systemSignal_normal_returnsMid() {
        let score = SystemSignal.score(cpuUsage: 0.3, memoryPressure: 0.3, idleMinutes: 10)
        XCTAssertGreaterThan(score, 0.4)
        XCTAssertLessThan(score, 0.8)
    }

    // MARK: - IntimacySignal

    func test_intimacy_startsAtZero() {
        let suite = UserDefaults(suiteName: "test_intimacy_zero")!
        suite.removeObject(forKey: "intimacy_value")
        let signal = IntimacySignal(defaults: suite)
        XCTAssertEqual(signal.score, 0.0, accuracy: 0.01)
    }

    func test_intimacy_increaseOnChat() {
        let suite = UserDefaults(suiteName: "test_intimacy_chat")!
        suite.removeObject(forKey: "intimacy_value")
        let signal = IntimacySignal(defaults: suite)
        signal.recordChat()
        signal.recordChat()
        XCTAssertGreaterThan(signal.score, 0.0)
    }

    func test_intimacy_clampedAt1() {
        let suite = UserDefaults(suiteName: "test_intimacy_clamp")!
        suite.removeObject(forKey: "intimacy_value")
        let signal = IntimacySignal(defaults: suite)
        for _ in 0..<100 { signal.recordChat() }
        XCTAssertLessThanOrEqual(signal.score, 1.0)
    }

    // MARK: - EmotionEngine blend

    func test_emotionEngine_highScores_returnsHappy() {
        let engine = EmotionEngine()
        let state = engine.computeState(timeScore: 0.9, intimacyScore: 0.8, systemScore: 0.7)
        XCTAssertEqual(state, .happy)
    }

    func test_emotionEngine_lowScores_returnsSleepy() {
        let engine = EmotionEngine()
        let state = engine.computeState(timeScore: 0.1, intimacyScore: 0.1, systemScore: 0.5)
        XCTAssertEqual(state, .sleepy)
    }

    // MARK: - IntimacySignal decay

    func test_intimacy_decaysWhenIdle() {
        let suite = UserDefaults(suiteName: "test_decay_\(UUID().uuidString)")!
        suite.removeObject(forKey: "intimacy_value")
        let signal = IntimacySignal(defaults: suite)
        // 先增加一些亲密度
        for _ in 0..<10 { signal.recordChat() }
        let before = signal.score
        // 模拟 idle > 30 分钟
        signal.tick(idleMinutes: 35)
        XCTAssertLessThan(signal.score, before, "idle > 30 分钟后亲密度应该下降")
    }

    func test_intimacy_noDecayWhenActive() {
        let suite = UserDefaults(suiteName: "test_nodecay_\(UUID().uuidString)")!
        suite.removeObject(forKey: "intimacy_value")
        let signal = IntimacySignal(defaults: suite)
        for _ in 0..<10 { signal.recordChat() }
        let before = signal.score
        // idle < 30 分钟，不应该衰减
        signal.tick(idleMinutes: 10)
        XCTAssertEqual(signal.score, before, accuracy: 0.001)
    }
}
