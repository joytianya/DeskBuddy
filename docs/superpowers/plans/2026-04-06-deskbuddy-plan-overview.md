# DeskBuddy Implementation Plan — Overview

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Build a macOS pixel-art desktop pet with emotion system, AI chat, and optional voice.

**Architecture:** Swift + SwiftUI app with SpriteKit for pixel rendering, NSPanel floating window, modular engines (PetEngine / EmotionEngine / AIBridge / VoiceModule) communicating via Combine publishers.

**Tech Stack:** Swift 5.9+, SwiftUI, SpriteKit, Combine, CoreData, AVFoundation, Speech Framework, Claude/OpenAI API

---

## Team (5 agents, parallel execution)

| Agent | Role | Owns |
|-------|------|------|
| **dev-core** | Mac 核心开发 | PetEngine, NSPanel 窗口, EmotionEngine |
| **dev-ai** | AI/语音开发 | AIBridge, VoiceModule, CoreData 持久化 |
| **dev-ui** | UI/交互开发 | SwiftUI 气泡 UI, 设置面板, 右键菜单 |
| **dev-art** | 像素美术 | Sprite sheet 规范, 3 套内置皮肤资源 |
| **dev-qa** | QA/集成 | 集成测试, macOS 权限验证, 打包 |

---

## Sprint 计划

| Sprint | 周期 | 目标 | 计划文件 |
|--------|------|------|---------|
| Sprint 0 | Week 1 | 项目脚手架 + 像素窗口跑通 | [sprint-0.md](2026-04-06-deskbuddy-plan-sprint-0.md) |
| Sprint 1 | Week 2–3 | PetEngine + EmotionEngine | [sprint-1.md](2026-04-06-deskbuddy-plan-sprint-1.md) |
| Sprint 2 | Week 4–5 | AIBridge + 对话 UI | [sprint-2.md](2026-04-06-deskbuddy-plan-sprint-2.md) |
| Sprint 3 | Week 6 | VoiceModule + 设置面板 + 打包 | [sprint-3.md](2026-04-06-deskbuddy-plan-sprint-3.md) |

---

## 文件结构

```
DeskBuddy/
├── DeskBuddy.xcodeproj
├── DeskBuddy/
│   ├── App/
│   │   ├── DeskBuddyApp.swift          # @main 入口
│   │   └── AppDelegate.swift           # NSPanel 生命周期
│   ├── Window/
│   │   ├── PetWindowController.swift   # NSPanel 管理, 拖拽, always-on-top
│   │   └── PetWindowView.swift         # SwiftUI 根视图
│   ├── Pet/
│   │   ├── PetEngine.swift             # SpriteKit 场景, 动画状态机
│   │   ├── SpriteLoader.swift          # 加载 sprite sheet, 整数倍缩放
│   │   └── PetState.swift              # 情绪状态枚举
│   ├── Emotion/
│   │   ├── EmotionEngine.swift         # 三维叠加计算
│   │   ├── TimeSignal.swift            # 时间维度
│   │   ├── IntimacySignal.swift        # 互动维度
│   │   └── SystemSignal.swift          # 系统感知维度
│   ├── AI/
│   │   ├── AIBridge.swift              # API 调用, 上下文管理
│   │   ├── ConversationStore.swift     # CoreData 对话持久化
│   │   └── SystemPromptBuilder.swift   # 注入情绪状态到 prompt
│   ├── Voice/
│   │   ├── VoiceInput.swift            # STT (Apple Speech / Whisper)
│   │   └── VoiceOutput.swift           # TTS (AVSpeech / ElevenLabs)
│   ├── UI/
│   │   ├── ChatBubbleView.swift        # 对话气泡
│   │   ├── SettingsView.swift          # 设置面板
│   │   └── ContextMenuView.swift       # 右键菜单
│   ├── Assets/
│   │   ├── Sprites/
│   │   │   ├── cat-sheet.png           # 猫皮肤 sprite sheet
│   │   │   ├── ghost-sheet.png         # 幽灵皮肤
│   │   │   └── robot-sheet.png         # 机器人皮肤
│   │   └── Assets.xcassets
│   └── Persistence/
│       └── DeskBuddy.xcdatamodeld      # CoreData schema
└── DeskBuddyTests/
    ├── EmotionEngineTests.swift
    ├── AIBridgeTests.swift
    └── PetEngineTests.swift
```
