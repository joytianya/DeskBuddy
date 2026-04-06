# DeskBuddy — Sprint 1: PetEngine + EmotionEngine

> **Owner:** dev-core（PetEngine + EmotionEngine）+ dev-art（皮肤资源）并行  
> **周期:** Week 2–3  
> **目标:** 像素宠物在屏幕上活动，情绪驱动动画切换

---

## Task 1.1: PetEngine — SpriteKit 场景（dev-core）

**Files:**
- Create: `DeskBuddy/Pet/PetEngine.swift`
- Modify: `DeskBuddy/Window/PetWindowView.swift`

- [ ] **Step 1: 创建 PetEngine（SKScene）**

```swift
// DeskBuddy/Pet/PetEngine.swift
import SpriteKit
import Combine

class PetEngine: SKScene {
    private var petNode: SKSpriteNode!
    private var currentState: PetState = .idle
    private var skinName: String = "cat-sheet"
    private var cancellables = Set<AnyCancellable>()

    // 外部通过此 subject 驱动情绪变化
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
        // 整数倍缩放，保持像素锐利
        petNode.texture?.filteringMode = .nearest
        petNode.setScale(4.0) // 默认 4x = 128px 显示
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

    func setScale(_ scale: CGFloat) {
        petNode.setScale(scale)
    }
}
```

- [ ] **Step 2: 将 PetWindowView 替换为 SpriteKit 视图**

```swift
// DeskBuddy/Window/PetWindowView.swift
import SwiftUI
import SpriteKit

struct PetWindowView: View {
    let engine: PetEngine

    init() {
        let scene = PetEngine(size: CGSize(width: 128, height: 128))
        scene.scaleMode = .aspectFit
        self.engine = scene
    }

    var body: some View {
        SpriteView(scene: engine, options: [.allowsTransparency])
            .frame(width: 128, height: 128)
            .background(Color.clear)
    }
}
```

- [ ] **Step 3: 运行，确认像素宠物出现并播放 idle 动画**

  Cmd+R，预期：屏幕上出现像素宠物，循环播放 idle 动画，背景透明

- [ ] **Step 4: Commit**

```bash
git add DeskBuddy/Pet/PetEngine.swift DeskBuddy/Window/PetWindowView.swift
git commit -m "feat: PetEngine SpriteKit scene, idle animation loop"
```

---

## Task 1.2: EmotionEngine — 时间维度（dev-core）

**Files:**
- Create: `DeskBuddy/Emotion/TimeSignal.swift`
- Create: `DeskBuddy/Emotion/EmotionEngine.swift`

- [ ] **Step 1: 写 TimeSignal 测试**

```swift
// DeskBuddyTests/EmotionEngineTests.swift
import XCTest
@testable import DeskBuddy

final class EmotionEngineTests: XCTestCase {
    func test_timeSignal_morning_returnsLow() {
        // 06:00 时间分数应偏低（懒洋洋）
        let score = TimeSignal.score(hour: 7)
        XCTAssertLessThan(score, 0.4)
    }

    func test_timeSignal_midday_returnsHigh() {
        // 10:00 精神饱满
        let score = TimeSignal.score(hour: 10)
        XCTAssertGreaterThan(score, 0.7)
    }

    func test_timeSignal_lateNight_returnsVeryLow() {
        // 03:00 深夜
        let score = TimeSignal.score(hour: 3)
        XCTAssertLessThan(score, 0.2)
    }
}
```

- [ ] **Step 2: 运行测试，确认失败**

  Cmd+U，预期：3 tests failed（TimeSignal 未定义）

- [ ] **Step 3: 实现 TimeSignal**

```swift
// DeskBuddy/Emotion/TimeSignal.swift
import Foundation

struct TimeSignal {
    /// 根据小时返回 0.0–1.0 的情绪分数
    static func score(hour: Int) -> Double {
        switch hour {
        case 6..<9:   return 0.3  // 刚睡醒，懒洋洋
        case 9..<12:  return 0.9  // 精神饱满
        case 12..<14: return 0.4  // 午后困倦
        case 14..<18: return 0.6  // 平稳
        case 18..<22: return 0.75 // 放松
        case 22..<24: return 0.3  // 安静
        case 0..<3:   return 0.2  // 深夜
        case 3..<6:   return 0.1  // 催睡
        default:      return 0.5
        }
    }

    static func currentScore() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())
        return score(hour: hour)
    }
}
```

- [ ] **Step 4: 运行测试，确认通过**

  Cmd+U，预期：3 tests passed

- [ ] **Step 5: Commit**

```bash
git add DeskBuddy/Emotion/TimeSignal.swift DeskBuddyTests/EmotionEngineTests.swift
git commit -m "feat: TimeSignal with hour-based emotion score, tests pass"
```

---

## Task 1.3: EmotionEngine — 互动维度（dev-core）

**Files:**
- Create: `DeskBuddy/Emotion/IntimacySignal.swift`

- [ ] **Step 1: 写测试**

```swift
// 追加到 DeskBuddyTests/EmotionEngineTests.swift
func test_intimacy_startsAtZero() {
    let signal = IntimacySignal()
    XCTAssertEqual(signal.score, 0.0, accuracy: 0.01)
}

func test_intimacy_increaseOnChat() {
    let signal = IntimacySignal()
    signal.recordChat()
    signal.recordChat()
    XCTAssertGreaterThan(signal.score, 0.0)
}

func test_intimacy_clampedAt1() {
    let signal = IntimacySignal()
    for _ in 0..<100 { signal.recordChat() }
    XCTAssertLessThanOrEqual(signal.score, 1.0)
}
```

- [ ] **Step 2: 运行测试，确认失败**

- [ ] **Step 3: 实现 IntimacySignal**

```swift
// DeskBuddy/Emotion/IntimacySignal.swift
import Foundation

class IntimacySignal: ObservableObject {
    // 亲密度 0–100，持久化到 UserDefaults
    private let key = "intimacy_value"
    private var rawValue: Double {
        get { UserDefaults.standard.double(forKey: key) }
        set { UserDefaults.standard.set(min(100, max(0, newValue)), forKey: key) }
    }

    /// 归一化到 0.0–1.0
    var score: Double { rawValue / 100.0 }

    func recordChat() { rawValue += 2 }
    func recordClick() { rawValue += 1 }

    /// 每分钟调用一次，静止超过 30 分钟后开始衰减
    func tick(idleMinutes: Int) {
        if idleMinutes > 30 { rawValue -= 1 }
    }
}
```

- [ ] **Step 4: 运行测试，确认通过**

- [ ] **Step 5: Commit**

```bash
git add DeskBuddy/Emotion/IntimacySignal.swift
git commit -m "feat: IntimacySignal with persistence, decay on idle"
```

---

## Task 1.4: EmotionEngine — 系统感知维度（dev-core）

**Files:**
- Create: `DeskBuddy/Emotion/SystemSignal.swift`

- [ ] **Step 1: 写测试**

```swift
// 追加到 DeskBuddyTests/EmotionEngineTests.swift
func test_systemSignal_highCPU_returnsLow() {
    let score = SystemSignal.score(cpuUsage: 0.85, memoryPressure: 0.3, idleMinutes: 5)
    XCTAssertLessThan(score, 0.3) // 高 CPU → 焦虑 → 低分
}

func test_systemSignal_idle_returnsLow() {
    let score = SystemSignal.score(cpuUsage: 0.1, memoryPressure: 0.1, idleMinutes: 50)
    XCTAssertLessThan(score, 0.4) // 长时间静止 → 无聊
}

func test_systemSignal_normal_returnsMid() {
    let score = SystemSignal.score(cpuUsage: 0.3, memoryPressure: 0.3, idleMinutes: 10)
    XCTAssertGreaterThan(score, 0.4)
    XCTAssertLessThan(score, 0.8)
}
```

- [ ] **Step 2: 实现 SystemSignal**

```swift
// DeskBuddy/Emotion/SystemSignal.swift
import Foundation

struct SystemSignal {
    static func score(cpuUsage: Double, memoryPressure: Double, idleMinutes: Int) -> Double {
        var s = 0.6 // 基准分
        if cpuUsage > 0.8 { s -= 0.4 }       // 高 CPU → 焦虑
        else if cpuUsage < 0.2 { s -= 0.2 }  // 低 CPU → 无聊
        if memoryPressure > 0.8 { s -= 0.3 } // 内存紧张
        if idleMinutes > 45 { s -= 0.2 }     // 长时间静止
        return max(0, min(1, s))
    }

    /// 读取真实系统 CPU 使用率（0.0–1.0）
    static func currentCPUUsage() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0.3 }
        let total = Double(info.cpu_ticks.0 + info.cpu_ticks.1 + info.cpu_ticks.2 + info.cpu_ticks.3)
        let idle = Double(info.cpu_ticks.3)
        return total > 0 ? 1.0 - (idle / total) : 0.3
    }
}
```

- [ ] **Step 3: 运行测试，确认通过**

- [ ] **Step 4: Commit**

```bash
git add DeskBuddy/Emotion/SystemSignal.swift
git commit -m "feat: SystemSignal CPU/memory/idle sensing"
```

---

## Task 1.5: EmotionEngine — 三维叠加（dev-core）

**Files:**
- Modify: `DeskBuddy/Emotion/EmotionEngine.swift`

- [ ] **Step 1: 写叠加测试**

```swift
// 追加到 DeskBuddyTests/EmotionEngineTests.swift
func test_emotionEngine_highScores_returnsHappy() {
    let engine = EmotionEngine()
    let state = engine.computeState(timeScore: 0.9, intimacyScore: 0.8, systemScore: 0.7)
    XCTAssertEqual(state, .happy)
}

func test_emotionEngine_lowScores_returnsSleepy() {
    let engine = EmotionEngine()
    let state = engine.computeState(timeScore: 0.1, intimacyScore: 0.1, systemScore: 0.5)
    XCTAssertEqual(state, .sleepy)
}
```

- [ ] **Step 2: 实现 EmotionEngine**

```swift
// DeskBuddy/Emotion/EmotionEngine.swift
import Foundation
import Combine

class EmotionEngine: ObservableObject {
    @Published private(set) var currentState: PetState = .idle

    private let intimacy = IntimacySignal()
    private var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.update()
        }
        update()
    }

    func stop() { timer?.invalidate() }

    func recordChat() { intimacy.recordChat(); update() }
    func recordClick() { intimacy.recordClick(); update() }

    private func update() {
        let t = TimeSignal.currentScore()
        let i = intimacy.score
        let s = SystemSignal.score(
            cpuUsage: SystemSignal.currentCPUUsage(),
            memoryPressure: 0.3, // TODO Sprint 2 接真实内存
            idleMinutes: 0       // TODO Sprint 2 接真实 idle 时间
        )
        currentState = computeState(timeScore: t, intimacyScore: i, systemScore: s)
    }

    func computeState(timeScore: Double, intimacyScore: Double, systemScore: Double) -> PetState {
        let combined = timeScore * 0.3 + intimacyScore * 0.4 + systemScore * 0.3
        switch combined {
        case 0.8...:  return .excited
        case 0.65...: return .happy
        case 0.5...:  return .idle
        case 0.35...: return .bored
        case 0.2...:  return .sleepy
        default:      return .anxious
        }
    }
}
```

- [ ] **Step 3: 在 AppDelegate 中连接 EmotionEngine → PetEngine**

```swift
// 修改 DeskBuddy/App/AppDelegate.swift
import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: PetWindowController?
    let emotionEngine = EmotionEngine()
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        windowController = PetWindowController(emotionEngine: emotionEngine)
        windowController?.showWindow(nil)
        emotionEngine.$currentState
            .sink { [weak self] state in
                self?.windowController?.petEngine.stateSubject.send(state)
            }
            .store(in: &cancellables)
        emotionEngine.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
```

- [ ] **Step 4: 更新 PetWindowController 接受 emotionEngine 参数**

```swift
// 修改 PetWindowController.swift convenience init
convenience init(emotionEngine: EmotionEngine) {
    // ... 同 Sprint 0 的 panel 设置 ...
    let view = PetWindowView(emotionEngine: emotionEngine)
    panel.contentView = NSHostingView(rootView: view)
    self.init(window: panel)
    enableDrag()
}
```

- [ ] **Step 5: 运行，确认宠物根据当前时间显示对应情绪动画**

- [ ] **Step 6: 运行所有测试**

  Cmd+U，预期：全部通过

- [ ] **Step 7: Commit**

```bash
git add DeskBuddy/Emotion/ DeskBuddy/App/AppDelegate.swift DeskBuddy/Window/
git commit -m "feat: EmotionEngine 3-signal blend, drives PetEngine animation"
```

---

## Sprint 1 完成标准

- [ ] 像素宠物在屏幕上显示，根据时间自动切换情绪动画
- [ ] 所有单元测试通过（EmotionEngine + PetEngine）
- [ ] 美术同学已按 sprite-spec.md 完成至少 1 套皮肤的 idle + happy + sleepy 3 个状态
