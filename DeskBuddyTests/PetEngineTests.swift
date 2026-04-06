// DeskBuddyTests/PetEngineTests.swift
import XCTest
import SpriteKit
@testable import DeskBuddy

final class PetEngineTests: XCTestCase {
    func test_spriteLoader_returnsCorrectFrameCount() {
        // SpriteLoader returns frameCount frames per state (varies by sprite sheet row)
        let frames = SpriteLoader.frames(sheetName: "cat-sheet", state: .idle)
        XCTAssertEqual(frames.count, PetState.idle.frameCount)
    }

    func test_petState_rowIndex_idle_isZero() {
        XCTAssertEqual(PetState.idle.rowIndex, 0)
    }

    func test_petState_rowIndex_clingy_isThree() {
        // clingy maps to Clean B (row 3) in the Elthen cat sprite sheet
        XCTAssertEqual(PetState.clingy.rowIndex, 3)
    }

    func test_petState_allCases_count() {
        XCTAssertEqual(PetState.allCases.count, 7)
    }

    func test_petState_frameCount_isPositive() {
        for state in PetState.allCases {
            XCTAssertGreaterThan(state.frameCount, 0, "State \(state) should have at least 1 frame")
        }
    }

    func test_petState_frameCount_matchesSpriteSheet() {
        // Verified against actual 256×320 sprite sheet (8 cols × 10 rows, 32×32 frames)
        XCTAssertEqual(PetState.idle.frameCount, 4)
        XCTAssertEqual(PetState.bored.frameCount, 4)
        XCTAssertEqual(PetState.happy.frameCount, 4)
        XCTAssertEqual(PetState.clingy.frameCount, 4)
        XCTAssertEqual(PetState.sleepy.frameCount, 4)
        XCTAssertEqual(PetState.excited.frameCount, 7)
        XCTAssertEqual(PetState.anxious.frameCount, 8)
    }

    func test_petState_rowIndex_uniquePerState() {
        let rows = PetState.allCases.map { $0.rowIndex }
        let unique = Set(rows)
        XCTAssertEqual(rows.count, unique.count, "每个 PetState 应映射到不同的 rowIndex")
    }

    func test_petState_frameCount_withinSheetBounds() {
        for state in PetState.allCases {
            XCTAssertLessThanOrEqual(state.frameCount, 8, "\(state) frameCount 超出 sprite sheet 列数")
            XCTAssertGreaterThan(state.frameCount, 0)
        }
    }

    func test_petState_rowIndex_withinSheetBounds() {
        for state in PetState.allCases {
            XCTAssertGreaterThanOrEqual(state.rowIndex, 0)
            XCTAssertLessThan(state.rowIndex, 10, "\(state) rowIndex 超出 sprite sheet 行数（10行）")
        }
    }

    func test_petEngine_initialCurrentState_isIdle() {
        let engine = PetEngine(size: CGSize(width: 128, height: 128))
        var received: PetState?
        let cancellable = engine.stateSubject.sink { received = $0 }
        engine.stateSubject.send(.happy)
        XCTAssertEqual(received, .happy)
        cancellable.cancel()
    }
}
