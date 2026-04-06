// DeskBuddy/Pet/PetEngine.swift
import SpriteKit
import Combine

class PetEngine: SKScene {
    private var petNode: SKSpriteNode!
    private var currentState: PetState = .idle
    private var skinName: String = "cat-sheet"
    private var cancellables = Set<AnyCancellable>()

    let stateSubject = PassthroughSubject<PetState, Never>()

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        setupPet()
        bindStateChanges()
    }

    private func setupPet() {
        let frames = SpriteLoader.frames(sheetName: skinName, state: .idle)
        petNode = SKSpriteNode(texture: frames[0])
        petNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        petNode.texture?.filteringMode = .nearest
        petNode.setScale(4.0)
        addChild(petNode)
        playAnimation(state: .idle)
    }

    private func bindStateChanges() {
        stateSubject
            .removeDuplicates()
            .sink { [weak self] newState in
                self?.playAnimation(state: newState)
            }
            .store(in: &cancellables)
    }

    func playAnimation(state: PetState) {
        currentState = state
        guard let petNode = petNode else { return }
        let frames = SpriteLoader.frames(sheetName: skinName, state: state)
        let textures = frames.map { t -> SKTexture in
            t.filteringMode = .nearest
            return t
        }
        let action = SKAction.repeatForever(
            SKAction.animate(with: textures, timePerFrame: 0.15)
        )
        petNode.removeAllActions()
        petNode.run(action, withKey: "animation")
    }

    func setSkin(_ name: String) {
        skinName = name
        playAnimation(state: currentState)
    }

    func setPetScale(_ scale: CGFloat) {
        petNode?.setScale(scale)
    }
}
