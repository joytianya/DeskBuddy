// DeskBuddyTests/PetEngineTests.swift
import XCTest
import SpriteKit
@testable import DeskBuddy

final class PetEngineTests: XCTestCase {
    func test_spriteLoader_returnsCorrectFrameCount() {
        // SpriteLoader should return 6 frames per state
        // In test environment SKTexture doesn't load real images — just verify count
        let frames = SpriteLoader.frames(sheetName: "cat-sheet", state: .idle)
        XCTAssertEqual(frames.count, 6)
    }

    func test_petState_rowIndex_matchesRawValue() {
        XCTAssertEqual(PetState.idle.rowIndex, 0)
        XCTAssertEqual(PetState.clingy.rowIndex, 6)
    }

    func test_petState_allCases_count() {
        XCTAssertEqual(PetState.allCases.count, 7)
    }

    func test_petState_frameCount_isAlwaysSix() {
        for state in PetState.allCases {
            XCTAssertEqual(state.frameCount, 6, "State \(state) should have 6 frames")
        }
    }
}
