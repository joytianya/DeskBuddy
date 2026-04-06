# DeskBuddy — Sprint 4: 动画节奏优化 + 情绪系统重构

> **Owner:** dev-core (PetEngine) + dev-art (动画规范)
> **周期:** Week 7
> **目标:** 宠物动画有节奏感，情绪系统更自然，状态映射合理

---

## 问题分析

### 当前问题
1. **跳跃无限循环** → `excited` 状态映射 Row 8 (Jump)，`repeatForever` 导致宠物一直跳
2. **动画太密集** → 每 0.15s 一帧，没有"呼吸"停顿感
3. **状态映射不合理** → `happy`/`clingy` 用清洁动画，语义不匹配
4. **缺乏过渡节奏** → 状态切换立即切动画，无自然间隔
5. **互动动画无限制** → 鼠标互动触发的动画会打断正常情绪流程

### 现有状态 → 动画映射（需重构）
| PetState | Sprite Row | 问题 |
|----------|------------|------|
| idle | 0 (Idle A) | ✅ OK |
| happy | 2 (Clean A) | ❌ 清洁 ≠ 开心 |
| sleepy | 6 (Sleep) | ✅ OK |
| anxious | 9 (Scared) | ✅ OK |
| bored | 1 (Idle B) | ⚠️ 不明显 |
| excited | 8 (Jump) | ❌ 一直跳 |
| clingy | 3 (Clean B) | ❌ 清洁 ≠ 粘人 |

---

## Task 4.0: 动画节奏系统设计

> **目标:** 定义动画播放节奏规则，让宠物有自然的"休息"间隔

### 动画节奏规则

```swift
// AnimationRhythm.swift
struct AnimationRhythm {
    let playDuration: TimeInterval    // 播放多久
    let pauseDuration: TimeInterval   // 停顿多久
    let frameInterval: TimeInterval   // 帧间隔
    
    static func forState(_ state: PetState) -> AnimationRhythm {
        switch state {
        case .idle:
            return AnimationRhythm(play: 2.0, pause: 3.0, frame: 0.20)
        case .happy:
            return AnimationRhythm(play: 1.5, pause: 2.5, frame: 0.15)
        case .sleepy:
            return AnimationRhythm(play: 4.0, pause: 1.0, frame: 0.30)
        case .anxious:
            return AnimationRhythm(play: 0.8, pause: 0.5, frame: 0.10)
        case .bored:
            return AnimationRhythm(play: 1.0, pause: 4.0, frame: 0.25)
        case .excited:
            return AnimationRhythm(play: 1.0, pause: 2.0, frame: 0.12, cycles: 2)
        case .clingy:
            return AnimationRhythm(play: 3.0, pause: 1.0, frame: 0.18)
        }
    }
}
```

### 节奏行为
- **播放 → 停顿 → 播放** 循环
- **excited 特殊处理**：跳 2 次后停顿，不无限跳
- **sleepy 缓慢**：帧间隔长，播放时间长（猫打瞌睡）
- **anxious 快速**：帧间隔短，停顿短（紧张颤抖）

---

## Task 4.1: PetEngine 动画节奏实现

**Files:**
- Modify: `DeskBuddy/Pet/PetEngine.swift`
- Create: `DeskBuddy/Pet/AnimationRhythm.swift`

### Step 1: 创建 AnimationRhythm 结构

```swift
// DeskBuddy/Pet/AnimationRhythm.swift
struct AnimationRhythm {
    let playDuration: TimeInterval
    let pauseDuration: TimeInterval
    let frameInterval: TimeInterval
    let maxCycles: Int?  // nil = 无限循环
    
    static func forState(_ state: PetState) -> AnimationRhythm {
        switch state {
        case .idle:    return AnimationRhythm(play: 2.0, pause: 3.0, frame: 0.20, maxCycles: nil)
        case .happy:   return AnimationRhythm(play: 1.5, pause: 2.5, frame: 0.15, maxCycles: nil)
        case .sleepy:  return AnimationRhythm(play: 4.0, pause: 1.0, frame: 0.30, maxCycles: nil)
        case .anxious: return AnimationRhythm(play: 0.8, pause: 0.5, frame: 0.10, maxCycles: nil)
        case .bored:   return AnimationRhythm(play: 1.0, pause: 4.0, frame: 0.25, maxCycles: nil)
        case .excited: return AnimationRhythm(play: 1.0, pause: 2.0, frame: 0.12, maxCycles: 2)
        case .clingy:  return AnimationRhythm(play: 3.0, pause: 1.0, frame: 0.18, maxCycles: nil)
        }
    }
}
```

### Step 2: 重构 playAnimation 方法

```swift
// DeskBuddy/Pet/PetEngine.swift
func playAnimation(state: PetState) {
    currentState = state
    rhythmTimer?.invalidate()
    
    let rhythm = AnimationRhythm.forState(state)
    let frames = SpriteLoader.frames(sheetName: skinName, state: state)
    let textures = frames.map { t -> SKTexture in
        t.filteringMode = .nearest
        return t
    }
    
    if let maxCycles = rhythm.maxCycles {
        // 有限循环（如 excited 跳 2 次）
        let cycleAction = SKAction.animate(with: textures, timePerFrame: rhythm.frameInterval)
        let sequence = SKAction.sequence([
            SKAction.repeat(cycleAction, count: maxCycles),
            SKAction.wait(forDuration: rhythm.pauseDuration)
        ])
        petNode.run(SKAction.repeatForever(sequence), withKey: "animation")
    } else {
        // 播放 → 停顿循环
        let playAction = SKAction.animate(with: textures, timePerFrame: rhythm.frameInterval)
        let sequence = SKAction.sequence([
            SKAction.repeat(playAction, count: Int(rhythm.playDuration / (rhythm.frameInterval * textures.count))),
            SKAction.wait(forDuration: rhythm.pauseDuration)
        ])
        petNode.run(SKAction.repeatForever(sequence), withKey: "animation")
    }
}
```

---

## Task 4.2: 状态 → 动画映射重构

> **目标:** 让状态名与动画内容语义匹配

### 新映射方案

| PetState | 新名称 | Sprite Row | 动画描述 |
|----------|--------|------------|----------|
| idle | idle | 0 (Idle A) | 站立轻微晃动 |
| happy | happy | 4 (Walk A) | 走路摇摆（看起来更开心） |
| sleepy | sleepy | 6 (Sleep) | 睡觉 |
| anxious | anxious | 9 (Scared) | 惊恐颤抖 |
| bored | bored | 7 (Paw) | 抓挠动作（无聊时抓东西） |
| excited | excited | 8 (Jump) | 跳跃（有节奏限制） |
| clingy | clingy | 5 (Walk B) | 走向主人（粘人） |

### 代码修改

```swift
// DeskBuddy/Pet/PetState.swift
var rowIndex: Int {
    switch self {
    case .idle:    return 0  // Idle A
    case .bored:   return 7  // Paw（抓挠）
    case .happy:   return 4  // Walk A
    case .clingy:  return 5  // Walk B（走向）
    case .excited: return 8  // Jump
    case .sleepy:  return 6  // Sleep
    case .anxious: return 9  // Scared
    }
}

var frameCount: Int {
    switch self {
    case .idle:    return 4
    case .bored:   return 4  // Paw row has 4 frames
    case .happy:   return 4  // Walk A has 4 frames
    case .clingy:  return 4  // Walk B has 4 frames
    case .excited: return 7  // Jump has 7 frames
    case .sleepy:  return 4
    case .anxious: return 8
    }
}
```

---

## Task 4.3: 情绪阈值调整

> **目标:** 让状态分布更合理，减少一直处于某极端状态

### 问题
当前阈值导致状态集中在 idle/excited，缺乏中间态过渡

### 新阈值方案

```swift
// DeskBuddy/Emotion/EmotionEngine.swift
func computeState(timeScore: Double, intimacyScore: Double, systemScore: Double) -> PetState {
    let combined = timeScore * 0.3 + intimacyScore * 0.4 + systemScore * 0.3
    
    // 新阈值分布（更平滑）
    switch combined {
    case 0.80...:  return .excited   // 很高兴（跳）
    case 0.60...: return .happy      // 开心
    case 0.45...: return .idle       // 正常
    case 0.30...: return .bored      // 无聊
    case 0.15...: return .sleepy     // 困倦
    default:      return .anxious    // 紧张（系统压力大）
    }
}
```

---

## Task 4.4: 互动动画优化

> **目标:** 鼠标互动动画更自然，不会无限打断

### 当前问题
- `triggerInteraction` 会打断正常动画流程
- 互动结束后可能状态已变化但动画不匹配

### 优化方案

```swift
// DeskBuddy/Pet/PetEngine.swift
private func triggerInteraction(state: PetState, duration: TimeInterval) {
    // 不再设置 isInteracting 标志，改为短暂叠加动画
    let rhythm = AnimationRhythm.forState(state)
    let frames = SpriteLoader.frames(sheetName: skinName, state: state)
    let textures = frames.map { $0.withFilteringMode(.nearest) }
    
    let playAction = SKAction.animate(with: textures, timePerFrame: rhythm.frameInterval)
    let cycles = rhythm.maxCycles ?? 1
    let interactionAction = SKAction.sequence([
        SKAction.repeat(playAction, count: cycles),
        SKAction.wait(forDuration: duration)
    ])
    
    petNode.run(interactionAction, withKey: "interaction") { [weak self] in
        // 恢复当前情绪状态动画
        self?.playAnimation(state: self?.currentState ?? .idle)
    }
}
```

---

## Task 4.5: 状态转换平滑过渡

> **目标:** 状态切换时有过渡动画，不突然切换

### 方案：状态优先级 + 过渡队列

```swift
// DeskBuddy/Emotion/EmotionEngine.swift
// 添加状态优先级
extension PetState {
    var priority: Int {
        switch self {
        case .anxious: return 5  // 最高，系统警告
        case .excited: return 4  // 互动触发
        case .happy:   return 3
        case .clingy:  return 2
        case .idle:    return 1
        case .bored:   return 0
        case .sleepy: return -1  // 最低
        }
    }
}
```

---

## 验收标准

- [ ] `excited` 状态宠物不会一直跳，跳 2 次后停顿
- [ ] 每个状态动画有播放 → 停顿 → 播放节奏
- [ ] 状态名与动画语义匹配（happy 不是清洁动作）
- [ ] 状态分布合理，不会长期处于极端状态
- [ ] 互动动画结束后恢复正常情绪流程

---

## 时间估计

| Task | 估计时间 |
|------|---------|
| 4.0 动画节奏设计 | 1h |
| 4.1 PetEngine 实现 | 2h |
| 4.2 状态映射重构 | 0.5h |
| 4.3 情绪阈值调整 | 0.5h |
| 4.4 互动动画优化 | 1h |
| 4.5 状态过渡平滑 | 1h |
| **总计** | **6h** |