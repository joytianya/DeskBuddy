// DeskBuddy/Pet/PetEngine.swift
import SpriteKit
import Combine

class PetEngine: SKScene {
    private var petNode: SKSpriteNode!
    private var currentState: PetState = .idle
    private var skinName: String = "cat-sheet"
    private var cancellables = Set<AnyCancellable>()

    // 互动状态（用于 bindStateChanges 检查）

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
                // 互动动画播放时不打断，结束后会恢复到 currentState
                guard self?.petNode?.action(forKey: "interaction") == nil else { return }
                self?.playAnimation(state: newState)
            }
            .store(in: &cancellables)
    }

    func playAnimation(state: PetState) {
        currentState = state
        guard let petNode = petNode else { return }

        let rhythm = AnimationRhythm.forState(state)
        let frames = SpriteLoader.frames(sheetName: skinName, state: state)
        let textures = frames.map { t -> SKTexture in
            t.filteringMode = .nearest
            return t
        }

        petNode.removeAction(forKey: "animation")

        if let maxCycles = rhythm.maxCycles {
            // 有限循环（如 excited 跳 2 次后停顿）
            let cycleAction = SKAction.animate(with: textures, timePerFrame: rhythm.frameInterval)
            let sequence = SKAction.sequence([
                SKAction.repeat(cycleAction, count: maxCycles),
                SKAction.wait(forDuration: rhythm.pauseDuration)
            ])
            petNode.run(SKAction.repeatForever(sequence), withKey: "animation")
        } else {
            // 播放 → 停顿循环
            let playAction = SKAction.animate(with: textures, timePerFrame: rhythm.frameInterval)
            // 计算播放期间内完整动画循环次数
            let cycleCount = max(1, Int(rhythm.playDuration / (rhythm.frameInterval * Double(textures.count))))
            let sequence = SKAction.sequence([
                SKAction.repeat(playAction, count: cycleCount),
                SKAction.wait(forDuration: rhythm.pauseDuration)
            ])
            petNode.run(SKAction.repeatForever(sequence), withKey: "animation")
        }
    }

    // MARK: - 鼠标互动

    /// 鼠标靠近时调用，distance 为鼠标到宠物窗口中心的距离（屏幕坐标 pt）
    func onMouseNear(distance: CGFloat, mouseX: CGFloat, speed: CGFloat) {
        guard let petNode = petNode else { return }

        // 根据鼠标在宠物左/右翻转朝向
        let petScreenX = view?.window?.frame.midX ?? 0
        let facingRight = mouseX > petScreenX
        let absScale = abs(petNode.xScale)
        guard absScale > 0 else { return }
        let targetScaleX = facingRight ? absScale : -absScale
        if petNode.xScale != targetScaleX {
            petNode.removeAction(forKey: "flip")
            petNode.xScale = targetScaleX
        }

        if distance < 80 {
            if speed > 400 {
                // 鼠标快速移动 → excited
                triggerInteraction(state: .excited, duration: 1.5)
            } else if distance < 40 {
                // 鼠标非常近 → clingy
                triggerInteraction(state: .clingy, duration: 2.0)
            }
        }
    }

    /// 拖拽宠物松手后翻滚
    func onDropped() {
        guard let petNode = petNode else { return }

        let roll = SKAction.sequence([
            SKAction.rotate(byAngle: .pi * 2, duration: 0.4),
            SKAction.rotate(toAngle: 0, duration: 0.1),
            SKAction.run { [weak self] in
                self?.playAnimation(state: self?.currentState ?? .idle)
            }
        ])
        petNode.removeAction(forKey: "animation")
        petNode.removeAction(forKey: "interaction")
        petNode.run(roll, withKey: "interaction")
    }

    /// 双击宠物 → 开心跳跃
    func onDoubleClick() {
        guard let petNode = petNode else { return }

        let jump = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 12, duration: 0.15),
            SKAction.moveBy(x: 0, y: -12, duration: 0.15),
            SKAction.moveBy(x: 0, y: 8, duration: 0.1),
            SKAction.moveBy(x: 0, y: -8, duration: 0.1),
        ])
        petNode.run(jump)
        triggerInteraction(state: .happy, duration: 1.5)
    }

    private func triggerInteraction(state: PetState, duration: TimeInterval) {
        guard let petNode = petNode else { return }

        let rhythm = AnimationRhythm.forState(state)
        let frames = SpriteLoader.frames(sheetName: skinName, state: state)
        let textures = frames.map { t -> SKTexture in
            t.filteringMode = .nearest
            return t
        }

        // 互动动画播放指定次数后恢复
        let playAction = SKAction.animate(with: textures, timePerFrame: rhythm.frameInterval)
        let cycles = rhythm.maxCycles ?? 1
        let interactionAction = SKAction.sequence([
            SKAction.repeat(playAction, count: cycles),
            SKAction.wait(forDuration: duration),
            SKAction.run { [weak self] in
                // 恢复当前情绪状态动画
                self?.playAnimation(state: self?.currentState ?? .idle)
            }
        ])

        petNode.removeAction(forKey: "animation")
        petNode.run(interactionAction, withKey: "interaction")
    }

    func setSkin(_ name: String) {
        skinName = name
        playAnimation(state: currentState)
    }

    func setPetScale(_ scale: CGFloat) {
        guard let petNode = petNode else { return }
        let sign: CGFloat = petNode.xScale < 0 ? -1 : 1
        petNode.xScale = scale * sign
        petNode.yScale = scale
    }
}
