// DeskBuddy/Pet/Dog3DModel.swift
import SceneKit

/// 程序生成的低多边形3D小狗模型
class Dog3DModel {

    /// 创建小狗节点
    static func createDogNode() -> SCNNode {
        let dog = SCNNode()
        dog.name = "dog"

        // 身体 - 椭球形（使用Sphere + scale）
        let body = SCNNode(geometry: SCNSphere(radius: 0.4))
        body.scale = SCNVector3(1.2, 0.8, 0.9)  // 椭球形状
        body.position = SCNVector3(0, 0.35, 0)
        body.name = "body"
        dog.addChildNode(body)

        // 头部 - 球形
        let head = SCNNode(geometry: SCNSphere(radius: 0.28))
        head.position = SCNVector3(0.5, 0.55, 0)
        head.name = "head"
        body.addChildNode(head)

        // 耳朵 - 圆锥形，可动
        let leftEar = SCNNode(geometry: SCNCone(topRadius: 0.02, bottomRadius: 0.12, height: 0.18))
        leftEar.position = SCNVector3(-0.08, 0.22, 0.15)
        leftEar.eulerAngles = SCNVector3(-0.4, 0, 0.1)
        leftEar.name = "leftEar"
        head.addChildNode(leftEar)

        let rightEar = SCNNode(geometry: SCNCone(topRadius: 0.02, bottomRadius: 0.12, height: 0.18))
        rightEar.position = SCNVector3(-0.08, 0.22, -0.15)
        rightEar.eulerAngles = SCNVector3(-0.4, 0, -0.1)
        rightEar.name = "rightEar"
        head.addChildNode(rightEar)

        // 鼻子 - 小球形
        let nose = SCNNode(geometry: SCNSphere(radius: 0.06))
        nose.position = SCNVector3(0.25, -0.05, 0)
        nose.name = "nose"
        head.addChildNode(nose)

        // 眼睛 - 小球形
        let leftEye = SCNNode(geometry: SCNSphere(radius: 0.05))
        leftEye.position = SCNVector3(0.12, 0.08, 0.12)
        leftEye.name = "leftEye"
        head.addChildNode(leftEye)

        let rightEye = SCNNode(geometry: SCNSphere(radius: 0.05))
        rightEye.position = SCNVector3(0.12, 0.08, -0.12)
        rightEye.name = "rightEye"
        head.addChildNode(rightEye)

        // 前腿
        let frontLeftLeg = createLeg()
        frontLeftLeg.position = SCNVector3(0.3, 0, 0.18)
        frontLeftLeg.name = "frontLeftLeg"
        dog.addChildNode(frontLeftLeg)

        let frontRightLeg = createLeg()
        frontRightLeg.position = SCNVector3(0.3, 0, -0.18)
        frontRightLeg.name = "frontRightLeg"
        dog.addChildNode(frontRightLeg)

        // 后腿
        let backLeftLeg = createLeg()
        backLeftLeg.position = SCNVector3(-0.35, 0, 0.18)
        backLeftLeg.name = "backLeftLeg"
        dog.addChildNode(backLeftLeg)

        let backRightLeg = createLeg()
        backRightLeg.position = SCNVector3(-0.35, 0, -0.18)
        backRightLeg.name = "backRightLeg"
        dog.addChildNode(backRightLeg)

        // 尾巴 - 圆锥形，可摇摆
        let tail = SCNNode(geometry: SCNCone(topRadius: 0.02, bottomRadius: 0.08, height: 0.25))
        tail.position = SCNVector3(-0.55, 0.5, 0)
        tail.eulerAngles = SCNVector3(0.8, 0, 0)  // 向上倾斜
        tail.name = "tail"
        dog.addChildNode(tail)

        // 应用材质
        applyMaterials(to: dog)

        return dog
    }

    /// 创建腿部节点
    private static func createLeg() -> SCNNode {
        let leg = SCNNode(geometry: SCNCylinder(radius: 0.08, height: 0.35))
        leg.position.y = 0.175
        return leg
    }

    /// 应用材质（浅色系 - 米色/奶油色）
    private static func applyMaterials(to node: SCNNode) {
        // 主色 - 米色
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = NSColor(red: 0.95, green: 0.9, blue: 0.8, alpha: 1.0)

        // 鼻子 - 深棕色
        let noseMaterial = SCNMaterial()
        noseMaterial.diffuse.contents = NSColor(red: 0.3, green: 0.2, blue: 0.15, alpha: 1.0)

        // 眼睛 - 黑色
        let eyeMaterial = SCNMaterial()
        eyeMaterial.diffuse.contents = NSColor.black

        // 应用到各部件
        for child in node.childNodes {
            if let geom = child.geometry {
                switch child.name {
                case "nose":
                    geom.materials = [noseMaterial]
                case "leftEye", "rightEye":
                    geom.materials = [eyeMaterial]
                default:
                    geom.materials = [bodyMaterial]
                }
            }
            // 递归处理子节点
            applyMaterials(to: child)
        }
    }

    /// 设置小狗颜色（用户自定义）
    static func setDogColor(_ node: SCNNode, color: NSColor) {
        let material = SCNMaterial()
        material.diffuse.contents = color
        // 保持默认 lightingModel (.blinn)，保留 3D 光影效果

        for child in node.childNodes {
            if let geom = child.geometry {
                // 不改变眼睛和鼻子颜色
                if child.name != "nose" && child.name != "leftEye" && child.name != "rightEye" {
                    geom.materials = [material]
                }
            }
            setDogColor(child, color: color)
        }
    }
}