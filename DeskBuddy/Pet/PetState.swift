// DeskBuddy/Pet/PetState.swift
import Foundation

// Sprite sheet: 256×320px, 32×32 per frame, 8 cols × 10 rows
// Row layout (Elthen 2D Pixel Art Cat Sprites):
//   0: Idle variant A    1: Idle variant B
//   2: Clean variant A   3: Clean variant B
//   4: Walk variant A    5: Walk variant B
//   6: Sleep             7: Paw
//   8: Jump              9: Scared
enum PetState: Int, CaseIterable {
    case idle = 0
    case happy = 1
    case sleepy = 2
    case anxious = 3
    case bored = 4
    case excited = 5
    case clingy = 6
    case lying = 7      // 趴在地上休息

    var rowIndex: Int {
        switch self {
        case .idle:    return 0  // Idle A
        case .happy:   return 4  // Walk A（走路摇摆，看起来开心）
        case .clingy:  return 5  // Walk B（走向主人，粘人）
        case .bored:   return 7  // Paw（抓挠动作，无聊）
        case .excited: return 8  // Jump
        case .sleepy:  return 6  // Sleep
        case .anxious: return 9  // Scared
        case .lying:   return 6  // Sleep（趴着休息，同 sleepy）
        }
    }

    var frameCount: Int {
        switch self {
        case .idle:    return 4  // Row 0: 4 frames
        case .happy:   return 4  // Row 4: 4 frames (Walk A)
        case .clingy:  return 4  // Row 5: 4 frames (Walk B)
        case .bored:   return 4  // Row 7: 4 frames (Paw)
        case .excited: return 7  // Row 8: 7 frames (jump)
        case .sleepy:  return 4  // Row 6: 4 frames
        case .anxious: return 8  // Row 9: 8 frames (scared)
        case .lying:   return 4  // Row 6: 4 frames（趴着）
        }
    }
}
