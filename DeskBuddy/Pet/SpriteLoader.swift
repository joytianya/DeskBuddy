// DeskBuddy/Pet/SpriteLoader.swift
import SpriteKit

struct SpriteLoader {
    /// Cuts frames for a given state out of a sprite sheet.
    /// - Parameters:
    ///   - sheetName: Asset catalog image name, e.g. "cat-sheet"
    ///   - state: The animation state to load
    ///   - frameSize: Size of one frame in pixels, default 32×32
    static func frames(sheetName: String, state: PetState, frameSize: CGSize = CGSize(width: 32, height: 32)) -> [SKTexture] {
        let sheet = SKTexture(imageNamed: sheetName)
        let sheetW = sheet.size().width
        let sheetH = sheet.size().height
        let frameW = frameSize.width / sheetW
        let frameH = frameSize.height / sheetH
        let row = state.rowIndex
        let y = 1.0 - CGFloat(row + 1) * frameH  // SpriteKit y-axis starts from bottom

        return (0..<state.frameCount).map { col in
            let x = CGFloat(col) * frameW
            let rect = CGRect(x: x, y: y, width: frameW, height: frameH)
            return SKTexture(rect: rect, in: sheet)
        }
    }
}
