// DeskBuddy/Pet/SceneKitEngine.swift
import SceneKit
import Combine

/// SceneKit 3D渲染引擎
/// 实现PetRenderEngine协议，渲染3D低多边形小狗
class SceneKitEngine: SCNScene, PetRenderEngine {
    private var dogNode: SCNNode!
    private(set) var currentState: PetState = .idle
    private var cancellables = Set<AnyCancellable>()

    let stateSubject = PassthroughSubject<PetState, Never>()

    override init() {
        super.init()
        background.contents = NSColor.clear
        setupDog()
        setupCameraAndLights()
        bindStateChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupDog() {
        dogNode = Dog3DModel.createDogNode()
        dogNode.position = SCNVector3(0, 0, 0)
        dogNode.scale = SCNVector3(4, 4, 4)  // 放大4倍确保可见
        rootNode.addChildNode(dogNode)
        playAnimation(state: .idle)
    }

    private func setupCameraAndLights() {
        // 相机 - 正面视角，明确看向狗
        let camera = SCNNode()
        camera.name = "camera"
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 60
        camera.position = SCNVector3(0, 0.5, 5)
        camera.look(at: SCNVector3(0, 0.5, 0))  // 明确看向狗的中心
        rootNode.addChildNode(camera)

        // 强环境光
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = NSColor.white
        rootNode.addChildNode(ambientLight)
    }

    private func bindStateChanges() {
        stateSubject
            .removeDuplicates()
            .sink { [weak self] newState in
                guard self?.dogNode?.action(forKey: "interaction") == nil else { return }
                self?.playAnimation(state: newState)
            }
            .store(in: &cancellables)
    }

    func playAnimation(state: PetState) {
        currentState = state
        guard let dogNode = dogNode else { return }

        dogNode.removeAction(forKey: "animation")

        let action = Dog3DAnimations.animationFor(state: state, dogNode: dogNode)
        dogNode.runAction(action, forKey: "animation")
    }

    // MARK: - 鼠标互动

    func onMouseNear(distance: CGFloat, mouseX: CGFloat, speed: CGFloat) {
        guard let dogNode = dogNode else { return }

        // 根据鼠标位置翻转朝向
        let targetScaleX: CGFloat = mouseX > 0 ? 1.0 : -1.0
        if dogNode.scale.x != targetScaleX {
            dogNode.scale.x = targetScaleX
        }

        if distance < 80 {
            if speed > 400 {
                triggerInteraction(state: .excited, duration: 1.5)
            } else if distance < 40 {
                triggerInteraction(state: .clingy, duration: 2.0)
            }
        }
    }

    func onDropped() {
        guard let dogNode = dogNode else { return }

        let roll = SCNAction.sequence([
            Dog3DAnimations.rollAction(),
            SCNAction.run { _ in
                self.playAnimation(state: self.currentState)
            }
        ])
        dogNode.removeAction(forKey: "animation")
        dogNode.removeAction(forKey: "interaction")
        dogNode.runAction(roll, forKey: "interaction")
    }

    func onDoubleClick() {
        guard let dogNode = dogNode else { return }

        let happyJump = SCNAction.group([
            Dog3DAnimations.jumpAction(),
            Dog3DAnimations.happyAnimation(dogNode)
        ])

        let interaction = SCNAction.sequence([
            SCNAction.repeat(happyJump, count: 2),
            SCNAction.wait(duration: 1.0),
            SCNAction.run { _ in
                self.playAnimation(state: self.currentState)
            }
        ])

        dogNode.removeAction(forKey: "animation")
        dogNode.runAction(interaction, forKey: "interaction")
    }

    private func triggerInteraction(state: PetState, duration: TimeInterval) {
        guard let dogNode = dogNode else { return }

        let action = Dog3DAnimations.animationFor(state: state, dogNode: dogNode)

        let interactionAction = SCNAction.sequence([
            action,
            SCNAction.wait(duration: duration),
            SCNAction.run { _ in
                self.playAnimation(state: self.currentState)
            }
        ])

        dogNode.removeAction(forKey: "animation")
        dogNode.runAction(interactionAction, forKey: "interaction")
    }

    func setSkin(_ name: String) {
        // 3D模式下皮肤名称无效，改用颜色
    }

    func setPetScale(_ scale: CGFloat) {
        guard let dogNode = dogNode else { return }
        let sign: CGFloat = dogNode.scale.x < 0 ? -1 : 1
        dogNode.scale = SCNVector3(scale * sign, scale, scale)
    }
}