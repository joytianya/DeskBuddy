// DeskBuddyTests/AIBridgeTests.swift
import XCTest
@testable import DeskBuddy

final class AIBridgeTests: XCTestCase {
    var store: ConversationStore!

    override func setUp() {
        super.setUp()
        store = ConversationStore(inMemory: true)
    }

    func test_conversationStore_saveAndRetrieve() {
        store.save(role: "user", content: "hello")
        store.save(role: "assistant", content: "hi there")
        let msgs = store.recentMessages(limit: 10)
        XCTAssertEqual(msgs.count, 2)
        XCTAssertEqual(msgs[0].role, "user")
        XCTAssertEqual(msgs[1].content, "hi there")
    }

    func test_conversationStore_limitWorks() {
        for i in 0..<25 { store.save(role: "user", content: "msg \(i)") }
        let msgs = store.recentMessages(limit: 20)
        XCTAssertEqual(msgs.count, 20)
    }

    func test_systemPrompt_containsEmotionState() {
        let prompt = SystemPromptBuilder.build(state: .happy, intimacyScore: 0.8)
        XCTAssertTrue(prompt.contains("happy"))
        XCTAssertTrue(prompt.contains("intimate"))
    }

    func test_systemPrompt_anxious_mentionsStress() {
        let prompt = SystemPromptBuilder.build(state: .anxious, intimacyScore: 0.3)
        XCTAssertTrue(prompt.contains("anxious") || prompt.contains("stress"))
    }

    // MARK: - SystemPromptBuilder (extended)

    func test_systemPrompt_allStates_nonEmpty() {
        for state in PetState.allCases {
            let prompt = SystemPromptBuilder.build(state: state, intimacyScore: 0.5)
            XCTAssertFalse(prompt.isEmpty, "Prompt for \(state) should not be empty")
        }
    }

    func test_systemPrompt_intimacyLevels_differ() {
        let low = SystemPromptBuilder.build(state: .idle, intimacyScore: 0.1)
        let high = SystemPromptBuilder.build(state: .idle, intimacyScore: 0.9)
        XCTAssertNotEqual(low, high)
    }

    // MARK: - ConversationStore (extended)

    func test_conversationStore_clearAll() {
        let store2 = ConversationStore(inMemory: true)
        store2.save(role: "user", content: "hello")
        store2.clearAll()
        let msgs = store2.recentMessages(limit: 10)
        XCTAssertEqual(msgs.count, 0)
    }

    func test_conversationStore_orderIsChronological() {
        let store2 = ConversationStore(inMemory: true)
        store2.save(role: "user", content: "first")
        store2.save(role: "assistant", content: "second")
        store2.save(role: "user", content: "third")
        let msgs = store2.recentMessages(limit: 10)
        XCTAssertEqual(msgs[0].content, "first")
        XCTAssertEqual(msgs[2].content, "third")
    }
}
