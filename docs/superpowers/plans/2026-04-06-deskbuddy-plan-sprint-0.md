# DeskBuddy — Sprint 0: 项目脚手架 + 像素窗口

> **Owner:** dev-core + dev-art（并行）  
> **周期:** Week 1  
> **目标:** Xcode 项目跑通，NSPanel 悬浮窗显示一个像素点，sprite sheet 规范确定

---

## Task 0.1: 创建 Xcode 项目（dev-core）

**Files:**
- Create: `DeskBuddy.xcodeproj`
- Create: `DeskBuddy/App/DeskBuddyApp.swift`
- Create: `DeskBuddy/App/AppDelegate.swift`

- [ ] **Step 1: 新建 macOS App 项目**

  Xcode → New Project → macOS → App  
  Product Name: `DeskBuddy`  
  Interface: SwiftUI  
  Language: Swift  
  取消勾选 "Include Tests"（后面手动加）

- [ ] **Step 2: 修改 DeskBuddyApp.swift，禁用默认窗口**

```swift
// DeskBuddy/App/DeskBuddyApp.swift
import SwiftUI

@main
struct DeskBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 不使用 WindowGroup，窗口由 AppDelegate 管理
        Settings { EmptyView() }
    }
}
```

- [ ] **Step 3: 创建 AppDelegate，启动时显示 NSPanel**

```swift
// DeskBuddy/App/AppDelegate.swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: PetWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // 不在 Dock 显示
        windowController = PetWindowController()
        windowController?.showWindow(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
```

- [ ] **Step 4: 编译确认无报错**

  Cmd+B，预期：Build Succeeded

- [ ] **Step 5: 创建 .gitignore**

```bash
curl -sL https://raw.githubusercontent.com/github/gitignore/main/Swift.gitignore > .gitignore
# 追加 DeskBuddy 特有的忽略项
cat >> .gitignore << 'EOF'
.superpowers/
*.xcuserstate
xcuserdata/
EOF
```

- [ ] **Step 6: Commit**

```bash
git init
git add .gitignore .
git commit -m "feat: init Xcode project, disable Dock icon, add .gitignore"
```

---

## Task 0.2: NSPanel 悬浮窗（dev-core）

**Files:**
- Create: `DeskBuddy/Window/PetWindowController.swift`
- Create: `DeskBuddy/Window/PetWindowView.swift`

- [ ] **Step 1: 创建 PetWindowController**

```swift
// DeskBuddy/Window/PetWindowController.swift
import AppKit
import SwiftUI

class PetWindowController: NSWindowController {
    convenience init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 128, height: 128),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.contentView = NSHostingView(rootView: PetWindowView())
        self.init(window: panel)
        enableDrag()
    }

    private func enableDrag() {
        guard let panel = window else { return }
        panel.isMovableByWindowBackground = true
    }
}
```

- [ ] **Step 2: 创建 PetWindowView（占位红色方块）**

```swift
// DeskBuddy/Window/PetWindowView.swift
import SwiftUI

struct PetWindowView: View {
    var body: some View {
        Rectangle()
            .fill(Color.red)
            .frame(width: 32, height: 32)
    }
}
```

- [ ] **Step 3: 运行，确认红色方块悬浮在所有窗口之上，可拖拽**

  Cmd+R，预期：屏幕左下角出现红色方块，可拖动，不遮挡鼠标点击其他应用

- [ ] **Step 4: Commit**

```bash
git add DeskBuddy/Window/
git commit -m "feat: NSPanel floating window, draggable, always-on-top"
```

---

## Task 0.3: Sprite Sheet 规范（dev-art）

**Files:**
- Create: `docs/sprite-spec.md`
- Create: `DeskBuddy/Assets/Sprites/cat-sheet.png`（占位，可用临时素材）

- [ ] **Step 1: 确定 sprite sheet 格式**

  每套皮肤一张 PNG，布局如下：
  - 原始像素尺寸：32×32 px / 帧
  - 每行一个状态，每列一帧
  - 状态顺序（行）：idle(0) / happy(1) / sleepy(2) / anxious(3) / bored(4) / excited(5) / clingy(6)
  - 每状态 6 帧
  - 整张 sheet 尺寸：192×224 px（32×6 列，32×7 行）

- [ ] **Step 2: 写 sprite-spec.md**

```markdown
# DeskBuddy Sprite Sheet 规范

## 尺寸
- 每帧：32×32 px
- 每状态：6 帧（横向排列）
- 状态数：7
- 整张 sheet：192px × 224px

## 状态行索引
| 行 | 状态 | 说明 |
|----|------|------|
| 0 | idle | 默认待机，轻微呼吸动画 |
| 1 | happy | 开心，蹦跳或摇尾 |
| 2 | sleepy | 打盹，眼睛半闭 |
| 3 | anxious | 焦虑，抖动冒汗 |
| 4 | bored | 无聊，踢腿打哈欠 |
| 5 | excited | 兴奋，快速蹦跳 |
| 6 | clingy | 黏人，蹭屏幕 |

## 格式
- PNG，透明背景
- 不抗锯齿（像素画风格）
- 命名：`{skin-name}-sheet.png`
```

- [ ] **Step 3: 从 itch.io 下载临时占位素材**

  推荐：https://itch.io/game-assets/free/tag-pixel-art/tag-characters  
  下载任意 32×32 像素猫/动物素材，重命名为 `cat-sheet.png`，放入 `DeskBuddy/Assets/Sprites/`

- [ ] **Step 4: Commit**

```bash
git add docs/sprite-spec.md DeskBuddy/Assets/Sprites/
git commit -m "docs: sprite sheet spec, add placeholder cat sprite"
```

---

## Task 0.4: SpriteLoader 骨架（dev-core）

**Files:**
- Create: `DeskBuddy/Pet/SpriteLoader.swift`
- Create: `DeskBuddy/Pet/PetState.swift`

- [ ] **Step 1: 定义 PetState 枚举**

```swift
// DeskBuddy/Pet/PetState.swift
import Foundation

enum PetState: Int, CaseIterable {
    case idle = 0
    case happy = 1
    case sleepy = 2
    case anxious = 3
    case bored = 4
    case excited = 5
    case clingy = 6

    var frameCount: Int { 6 }
    var rowIndex: Int { rawValue }
}
```

- [ ] **Step 2: 创建 SpriteLoader**

```swift
// DeskBuddy/Pet/SpriteLoader.swift
import SpriteKit

struct SpriteLoader {
    /// 从 sprite sheet 切出指定状态的所有帧
    /// - Parameters:
    ///   - sheetName: Assets 中的图片名，如 "cat-sheet"
    ///   - state: 要加载的状态
    ///   - frameSize: 单帧像素尺寸，默认 32×32
    static func frames(sheetName: String, state: PetState, frameSize: CGSize = CGSize(width: 32, height: 32)) -> [SKTexture] {
        let sheet = SKTexture(imageNamed: sheetName)
        let sheetW = sheet.size().width
        let sheetH = sheet.size().height
        let frameW = frameSize.width / sheetW
        let frameH = frameSize.height / sheetH
        let y = 1.0 - CGFloat(state.rowIndex + 1) * frameH  // SpriteKit y 轴从底部起

        return (0..<state.frameCount).map { col in
            let x = CGFloat(col) * frameW
            let rect = CGRect(x: x, y: y, width: frameW, height: frameH)
            return SKTexture(rect: rect, in: sheet)
        }
    }
}
```

- [ ] **Step 3: 写单元测试**

```swift
// DeskBuddyTests/PetEngineTests.swift
import XCTest
import SpriteKit
@testable import DeskBuddy

final class PetEngineTests: XCTestCase {
    func test_spriteLoader_returnsCorrectFrameCount() {
        // SpriteLoader 应返回 6 帧
        // 注意：在测试环境中 SKTexture 不加载真实图片，只验证数量
        let frames = SpriteLoader.frames(sheetName: "cat-sheet", state: .idle)
        XCTAssertEqual(frames.count, 6)
    }

    func test_petState_rowIndex_matchesRawValue() {
        XCTAssertEqual(PetState.idle.rowIndex, 0)
        XCTAssertEqual(PetState.clingy.rowIndex, 6)
    }
}
```

- [ ] **Step 4: 运行测试**

  Cmd+U，预期：2 tests passed

- [ ] **Step 5: Commit**

```bash
git add DeskBuddy/Pet/ DeskBuddyTests/
git commit -m "feat: PetState enum, SpriteLoader frame extraction"
```

---

## Sprint 0 完成标准

- [ ] `git log` 显示 4 个 commit
- [ ] 运行 app，屏幕上出现可拖拽的红色方块（后续 Sprint 1 替换为真实像素宠物）
- [ ] 所有单元测试通过
- [ ] sprite-spec.md 已写，美术同学可以按规范开始画
