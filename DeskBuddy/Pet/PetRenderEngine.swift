// DeskBuddy/Pet/PetRenderEngine.swift
import Foundation
import Combine
import CoreGraphics

/// 渲染模式枚举
enum RenderMode: String, Codable, CaseIterable {
    case sprite2D = "2d"
    case sceneKit3D = "3d"

    var displayName: String {
        switch self {
        case .sprite2D: return "2D 像素风"
        case .sceneKit3D: return "3D 立体"
        }
    }
}

/// 宠物渲染引擎协议
/// 抽象渲染层，支持2D(SpriteKit)和3D(SceneKit)实现
protocol PetRenderEngine: AnyObject {
    /// 状态变化发布者
    var stateSubject: PassthroughSubject<PetState, Never> { get }

    /// 当前状态
    var currentState: PetState { get }

    /// 播放指定状态的动画
    func playAnimation(state: PetState)

    /// 鼠标靠近时的互动
    /// - Parameters:
    ///   - distance: 鼠标到宠物中心的距离
    ///   - mouseX: 鼠标X坐标（屏幕坐标）
    ///   - speed: 鼠标移动速度
    func onMouseNear(distance: CGFloat, mouseX: CGFloat, speed: CGFloat)

    /// 拖拽松手后的翻滚动画
    func onDropped()

    /// 双击时的开心跳跃
    func onDoubleClick()

    /// 设置皮肤（仅2D模式有效）
    func setSkin(_ name: String)

    /// 设置宠物大小缩放
    func setPetScale(_ scale: CGFloat)

    /// 设置渲染模式（用于动态切换）
    func setRenderMode(_ mode: RenderMode)
}

// MARK: - 默认实现扩展

extension PetRenderEngine {
    func setRenderMode(_ mode: RenderMode) {
        // 默认空实现，子类可覆盖
    }
}