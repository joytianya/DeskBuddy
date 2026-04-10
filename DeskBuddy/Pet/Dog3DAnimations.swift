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

    /// idle - 微微呼吸（更慢更自然）
    static func idleAnimation() -> SCNAction {
        let breathe = SCNAction.sequence([
            SCNAction.scale(to: 1.02, duration: 1.5),  // 更慢的放大
            SCNAction.scale(to: 1.0, duration: 1.5),   // 更慢的缩小
            SCNAction.wait(duration: 2.0)              // 添加停顿
        ])
        return SCNAction.repeatForever(breathe)
    }

    /// happy - 尾巴快速摇摆
    static func happyAnimation(_ dogNode: SCNNode) -> SCNAction {
        let tail = dogNode.childNode(withName: "tail", recursively: true)
        let wag = SCNAction.sequence([
            SCNAction.rotateTo(x: 0.8, y: 0, z: 0.4, duration: 0.15),
            SCNAction.rotateTo(x: 0.8, y: 0, z: -0.4, duration: 0.15)
        ])
        let tailWag = SCNAction.repeatForever(wag)

        // 身体轻微跳跃
        let bounce = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.1, z: 0, duration: 0.2),
            SCNAction.moveBy(x: 0, y: -0.1, z: 0, duration: 0.2)
        ])

        return SCNAction.group([
            SCNAction.repeatForever(bounce),
            tailWag
        ])
    }

    /// excited - 连续跳跃 + 尾巴疯狂摇摆
    static func excitedAnimation(_ dogNode: SCNNode) -> SCNAction {
        let jump = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 0.15),
            SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: 0.15)
        ])

        let wag = SCNAction.sequence([
            SCNAction.rotateTo(x: 0.8, y: 0, z: 0.5, duration: 0.08),
            SCNAction.rotateTo(x: 0.8, y: 0, z: -0.5, duration: 0.08)
        ])

        return SCNAction.group([
            SCNAction.repeat(jump, count: 3),
            SCNAction.repeatForever(wag)
        ])
    }

    /// sleepy - 缓慢呼吸
    static func sleepyAnimation() -> SCNAction {
        let breathe = SCNAction.sequence([
            SCNAction.scale(to: 0.98, duration: 2.0),
            SCNAction.scale(to: 1.0, duration: 2.0)
        ])
        return SCNAction.repeatForever(breathe)
    }

    /// lying - 身体躺下
    static func lyingAnimation() -> SCNAction {
        let lieDown = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: -0.25, z: 0, duration: 0.4),
            SCNAction.rotateTo(x: -1.0, y: 0, z: 0, duration: 0.4)
        ])

        let breathe = SCNAction.sequence([
            SCNAction.scale(to: 0.95, duration: 3.0),
            SCNAction.scale(to: 1.0, duration: 3.0)
        ])

        return SCNAction.sequence([
            lieDown,
            SCNAction.repeatForever(breathe)
        ])
    }

    /// bored - 偶尔摇头
    static func boredAnimation(_ dogNode: SCNNode) -> SCNAction {
        let head = dogNode.childNode(withName: "head", recursively: true)
        let shakeHead = SCNAction.sequence([
            SCNAction.wait(duration: 2.0),
            SCNAction.rotateTo(x: 0, y: 0.2, z: 0, duration: 0.3),
            SCNAction.rotateTo(x: 0, y: -0.2, z: 0, duration: 0.3),
            SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.3),
            SCNAction.wait(duration: 3.0)
        ])
        return SCNAction.repeatForever(shakeHead)
    }

    /// anxious - 快速颤抖
    static func anxiousAnimation() -> SCNAction {
        let shake = SCNAction.sequence([
            SCNAction.moveBy(x: 0.03, y: 0, z: 0, duration: 0.05),
            SCNAction.moveBy(x: -0.03, y: 0, z: 0, duration: 0.05)
        ])
        return SCNAction.repeatForever(shake)
    }

    /// clingy - 摇尾巴 + 身体轻微前倾
    static func clingyAnimation(_ dogNode: SCNNode) -> SCNAction {
        let wag = SCNAction.sequence([
            SCNAction.rotateTo(x: 0.8, y: 0, z: 0.3, duration: 0.12),
            SCNAction.rotateTo(x: 0.8, y: 0, z: -0.3, duration: 0.12)
        ])

        let lean = SCNAction.sequence([
            SCNAction.moveBy(x: 0.05, y: 0, z: 0, duration: 0.4),
            SCNAction.moveBy(x: -0.05, y: 0, z: 0, duration: 0.4)
        ])

        return SCNAction.group([
            SCNAction.repeatForever(wag),
            SCNAction.repeatForever(lean)
        ])
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
}