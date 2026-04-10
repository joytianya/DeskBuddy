// DeskBuddy/Pet/Dog3DAnimations.swift
import SceneKit

/// 3D小狗动画系统
struct Dog3DAnimations {

    /// 获取指定状态的动画
    static func animationFor(state: PetState, dogNode: SCNNode) -> SCNAction {
        switch state {
        case .idle:
            return idleAnimation()
        case .happy:
            return happyAnimation(dogNode)
        case .excited:
            return excitedAnimation(dogNode)
        case .sleepy:
            return sleepyAnimation()
        case .lying:
            return lyingAnimation()
        case .bored:
            return boredAnimation(dogNode)
        case .anxious:
            return anxiousAnimation()
        case .clingy:
            return clingyAnimation(dogNode)
        }
    }

    /// idle - 微微呼吸（使用 AnimationRhythm）
    static func idleAnimation() -> SCNAction {
        let rhythm = AnimationRhythm.forState(.idle)
        // 使用 rhythm.frameInterval 作为呼吸动画的帧速度
        let breatheDuration = rhythm.playDuration / 2  // 单次呼吸（放大+缩小）
        let breathe = SCNAction.sequence([
            SCNAction.scale(to: 1.02, duration: breatheDuration),
            SCNAction.scale(to: 1.0, duration: breatheDuration)
        ])
        // maxCycles 控制呼吸次数，然后停顿
        let cycles = rhythm.maxCycles ?? 1
        let sequence = SCNAction.sequence([
            SCNAction.repeat(breathe, count: cycles),
            SCNAction.wait(duration: rhythm.pauseDuration)
        ])
        return SCNAction.repeatForever(sequence)
    }

    /// happy - 尾巴快速摇摆（使用 AnimationRhythm，针对尾巴节点）
    static func happyAnimation(_ dogNode: SCNNode) -> SCNAction {
        let rhythm = AnimationRhythm.forState(.happy)
        // 使用尾巴摇摆辅助函数
        let wagDuration = rhythm.frameInterval
        let wag = tailWagAction(dogNode, intensity: 0.35, duration: wagDuration)

        // 身体轻微跳跃
        let bounce = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.1, z: 0, duration: 0.2),
            SCNAction.moveBy(x: 0, y: -0.1, z: 0, duration: 0.2)
        ])

        // 计算 playDuration 内的完整动作次数
        let bounceCycleDuration = 0.4
        let cycles = max(1, Int(rhythm.playDuration / bounceCycleDuration))

        let sequence = SCNAction.sequence([
            SCNAction.group([
                SCNAction.repeat(bounce, count: cycles),
                SCNAction.repeat(wag, count: cycles * 2)  // 尾巴摇摆更快
            ]),
            SCNAction.wait(duration: rhythm.pauseDuration)
        ])
        return SCNAction.repeatForever(sequence)
    }

    /// excited - 连续跳跃 + 尾巴疯狂摇摆（使用 AnimationRhythm，针对尾巴节点）
    static func excitedAnimation(_ dogNode: SCNNode) -> SCNAction {
        let rhythm = AnimationRhythm.forState(.excited)
        let jump = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: rhythm.frameInterval),
            SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: rhythm.frameInterval)
        ])

        // 使用尾巴摇摆辅助函数（更大幅度）
        let wag = tailWagAction(dogNode, intensity: 0.5, duration: 0.08)

        // excited 有 maxCycles = 2，跳完后停顿
        let cycles = rhythm.maxCycles ?? 2
        let sequence = SCNAction.sequence([
            SCNAction.group([
                SCNAction.repeat(jump, count: cycles),
                SCNAction.repeat(wag, count: cycles * 4)  // 尾巴摇摆更快
            ]),
            SCNAction.wait(duration: rhythm.pauseDuration)
        ])
        return SCNAction.repeatForever(sequence)
    }

    /// sleepy - 缓慢呼吸（使用 AnimationRhythm）
    static func sleepyAnimation() -> SCNAction {
        let rhythm = AnimationRhythm.forState(.sleepy)
        // 使用 rhythm.frameInterval 作为呼吸节奏
        let breatheDuration = rhythm.frameInterval * 4  // 更慢的呼吸
        let breathe = SCNAction.sequence([
            SCNAction.scale(to: 0.98, duration: breatheDuration),
            SCNAction.scale(to: 1.0, duration: breatheDuration)
        ])
        // 计算 playDuration 内的完整呼吸次数
        let cycles = max(1, Int(rhythm.playDuration / (breatheDuration * 2)))
        let sequence = SCNAction.sequence([
            SCNAction.repeat(breathe, count: cycles),
            SCNAction.wait(duration: rhythm.pauseDuration)
        ])
        return SCNAction.repeatForever(sequence)
    }

    /// lying - 身体躺下（使用 AnimationRhythm）
    static func lyingAnimation() -> SCNAction {
        let rhythm = AnimationRhythm.forState(.lying)
        let lieDown = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: -0.25, z: 0, duration: 0.4),
            SCNAction.rotateTo(x: -1.0, y: 0, z: 0, duration: 0.4)
        ])

        // 使用 rhythm.frameInterval 作为呼吸节奏
        let breatheDuration = rhythm.frameInterval * 3
        let breathe = SCNAction.sequence([
            SCNAction.scale(to: 0.95, duration: breatheDuration),
            SCNAction.scale(to: 1.0, duration: breatheDuration)
        ])

        // 计算 playDuration 内的完整呼吸次数
        let cycles = max(1, Int(rhythm.playDuration / (breatheDuration * 2)))
        let sequence = SCNAction.sequence([
            lieDown,
            SCNAction.repeat(breathe, count: cycles),
            SCNAction.wait(duration: rhythm.pauseDuration)
        ])
        return SCNAction.repeatForever(sequence)
    }

    /// bored - 偶尔摇头（使用 AnimationRhythm，仅针对头部）
    static func boredAnimation(_ dogNode: SCNNode) -> SCNAction {
        let rhythm = AnimationRhythm.forState(.bored)
        // 找到头部节点，只对头部进行摇动
        let headNode = dogNode.childNode(withName: "body", recursively: true)?
            .childNode(withName: "head", recursively: true)

        // 摇头动作（若找到头部则针对头部，否则作用于整体）
        let shakeHead: SCNAction
        if let head = headNode {
            // 保存原始角度
            let originalRotation = head.eulerAngles
            shakeHead = SCNAction.sequence([
                SCNAction.run { _ in head.eulerAngles = SCNVector3(originalRotation.x, originalRotation.y + 0.25, originalRotation.z) },
                SCNAction.wait(duration: 0.3),
                SCNAction.run { _ in head.eulerAngles = SCNVector3(originalRotation.x, originalRotation.y - 0.25, originalRotation.z) },
                SCNAction.wait(duration: 0.3),
                SCNAction.run { _ in head.eulerAngles = originalRotation }
            ])
        } else {
            // fallback: 作用于整体
            shakeHead = SCNAction.sequence([
                SCNAction.rotateTo(x: 0, y: 0.2, z: 0, duration: 0.3),
                SCNAction.rotateTo(x: 0, y: -0.2, z: 0, duration: 0.3),
                SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.3)
            ])
        }

        // 添加腿部微动（增加生动感）
        let legShift = legShiftAction(dogNode, duration: 0.5)

        // 摇头动作总时长约 0.9s
        let shakeDuration = 0.9
        let cycles = max(1, Int(rhythm.playDuration / shakeDuration))
        let sequence = SCNAction.sequence([
            SCNAction.group([SCNAction.repeat(shakeHead, count: cycles), legShift]),
            SCNAction.wait(duration: rhythm.pauseDuration)
        ])
        return SCNAction.repeatForever(sequence)
    }

    /// anxious - 快速颤抖（使用 AnimationRhythm）
    static func anxiousAnimation() -> SCNAction {
        let rhythm = AnimationRhythm.forState(.anxious)
        // 使用 rhythm.frameInterval 作为颤抖节奏
        let shake = SCNAction.sequence([
            SCNAction.moveBy(x: 0.03, y: 0, z: 0, duration: rhythm.frameInterval),
            SCNAction.moveBy(x: -0.03, y: 0, z: 0, duration: rhythm.frameInterval)
        ])
        // 计算 playDuration 内的完整颤抖次数
        let shakeCycleDuration = rhythm.frameInterval * 2
        let cycles = max(1, Int(rhythm.playDuration / shakeCycleDuration))
        let sequence = SCNAction.sequence([
            SCNAction.repeat(shake, count: cycles),
            SCNAction.wait(duration: rhythm.pauseDuration)
        ])
        return SCNAction.repeatForever(sequence)
    }

    /// clingy - 摇尾巴 + 身体轻微前倾（使用 AnimationRhythm，针对尾巴节点）
    static func clingyAnimation(_ dogNode: SCNNode) -> SCNAction {
        let rhythm = AnimationRhythm.forState(.clingy)
        // 使用尾巴摇摆辅助函数（中等幅度）
        let wagDuration = rhythm.frameInterval
        let wag = tailWagAction(dogNode, intensity: 0.3, duration: wagDuration)

        let lean = SCNAction.sequence([
            SCNAction.moveBy(x: 0.05, y: 0, z: 0, duration: 0.4),
            SCNAction.moveBy(x: -0.05, y: 0, z: 0, duration: 0.4)
        ])

        // 计算 playDuration 内的完整动作次数
        let leanCycleDuration = 0.8
        let cycles = max(1, Int(rhythm.playDuration / leanCycleDuration))

        let sequence = SCNAction.sequence([
            SCNAction.group([
                SCNAction.repeat(lean, count: cycles),
                SCNAction.repeat(wag, count: cycles * 4)  // 尾巴摇摆更快
            ]),
            SCNAction.wait(duration: rhythm.pauseDuration)
        ])
        return SCNAction.repeatForever(sequence)
    }

    // MARK: - 互动动画

    /// 跳跃动作（用于双击）
    static func jumpAction() -> SCNAction {
        return SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.35, z: 0, duration: 0.12),
            SCNAction.moveBy(x: 0, y: -0.35, z: 0, duration: 0.12),
            SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 0.1),
            SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 0.1)
        ])
    }

    /// 翻滚动作（用于拖拽松手）
    static func rollAction() -> SCNAction {
        return SCNAction.sequence([
            SCNAction.rotateBy(x: CGFloat.pi * 2, y: 0, z: 0, duration: 0.4),
            SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.1)
        ])
    }

    // MARK: - 辅助动画

    /// 腿部微动（增加生动感）
    private static func legShiftAction(_ dogNode: SCNNode, duration: TimeInterval) -> SCNAction {
        // 找到腿部节点
        let frontLeft = dogNode.childNode(withName: "frontLeftLeg", recursively: true)
        let frontRight = dogNode.childNode(withName: "frontRightLeg", recursively: true)
        let backLeft = dogNode.childNode(withName: "backLeftLeg", recursively: true)
        let backRight = dogNode.childNode(withName: "backRightLeg", recursively: true)

        guard frontLeft != nil && frontRight != nil && backLeft != nil && backRight != nil else {
            return SCNAction.wait(duration: duration)  // 无腿部节点时返回空动作
        }

        // 腿部轻微移动（模拟站姿调整）
        return SCNAction.sequence([
            SCNAction.run { _ in
                frontLeft?.position.z += 0.02
                backRight?.position.z -= 0.02
            },
            SCNAction.wait(duration: duration),
            SCNAction.run { _ in
                frontLeft?.position.z -= 0.02
                backRight?.position.z += 0.02
            },
            SCNAction.wait(duration: duration)
        ])
    }

    /// 尾巴摇摆（针对尾巴节点）
    private static func tailWagAction(_ dogNode: SCNNode, intensity: CGFloat, duration: TimeInterval) -> SCNAction {
        let tailNode = dogNode.childNode(withName: "tail", recursively: true)
        guard let tail = tailNode else {
            // fallback: 整体轻微摇动
            return SCNAction.sequence([
                SCNAction.rotateTo(x: 0.8 + intensity, y: 0, z: intensity * 0.5, duration: duration),
                SCNAction.rotateTo(x: 0.8 + intensity, y: 0, z: -intensity * 0.5, duration: duration)
            ])
        }

        // 保存原始角度
        let originalRotation = tail.eulerAngles
        return SCNAction.sequence([
            SCNAction.run { _ in tail.eulerAngles = SCNVector3(originalRotation.x, originalRotation.y, originalRotation.z + intensity) },
            SCNAction.wait(duration: duration),
            SCNAction.run { _ in tail.eulerAngles = SCNVector3(originalRotation.x, originalRotation.y, originalRotation.z - intensity) },
            SCNAction.wait(duration: duration)
        ])
    }
}