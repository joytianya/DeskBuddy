# 🐱 DeskBuddy

```
   ╭──────────────────────────────────────╮
   │  ╭─────╮                             │
   │  │ ◠ ◡ │   DeskBuddy                 │
   │  ╰─────╯   Your Desktop Pixel Pet    │
   │     ∧     macOS Companion            │
   ╰──────────────────────────────────────╯
```

**DeskBuddy** is a charming pixel-art desktop pet for macOS. It lives on your desktop, reacts to your mouse, responds to system status, and can chat with you via AI.

## ✨ Features

### 🎨 Desktop Pet
- Cute pixel-art companion that roams your desktop
- Multiple skins: Cat, Ghost, Robot
- Customizable size and color

### 💭 Emotion System
- Pet mood changes based on system state:
  - CPU usage → Energy level
  - Memory pressure → Stress level
  - Time of day → Sleepiness
- Visual feedback through animations and expressions

### 🤖 AI Chat
- Built-in chat panel for conversations
- OpenAI-compatible API support
- Streaming responses (SSE)
- Configure your own API endpoint and model
- Default: Qwen 3.5 Plus

### 🖱️ Mouse Interaction
- **Hover**: Pet reacts when mouse approaches
- **Follow**: Eyes track cursor movement
- **Drag**: Pet rolls and bounces when dragged
- **Double-click**: Pet jumps excitedly
- **Direction flip**: Pet turns toward cursor

### 🎤 Voice (Optional)
- Speech input via microphone
- Text-to-speech for AI responses
- Requires microphone permissions

### ⚙️ Settings
- API endpoint & key configuration
- Model selection
- Pet size adjustment
- Theme color customization
- Voice toggle

## 📦 Installation

### Download (Coming Soon)
Download the latest DMG from [Releases](https://github.com/yourusername/DeskBuddy/releases).

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/DeskBuddy.git
   cd DeskBuddy
   ```

2. Open in Xcode:
   ```bash
   open DeskBuddy.xcodeproj
   ```

   Or create project via Xcode (see [SETUP.md](SETUP.md) for first-time setup).

3. Build and run:
   ```bash
   # Via Xcode: Product > Run
   # Or command line:
   xcodebuild -project DeskBuddy.xcodeproj -scheme DeskBuddy build
   ```

## 🔧 Configuration

### API Setup
1. Open Settings (click pet or menu bar icon)
2. Enter your OpenAI-compatible API endpoint
3. Add your API key
4. Select your preferred model

**Supported APIs:**
- OpenAI (official)
- Azure OpenAI
- Local models (Ollama, LM Studio)
- Any OpenAI-compatible endpoint

### Example Configuration
| Setting | Value |
|---------|-------|
| Endpoint | `https://api.openai.com/v1` |
| API Key | `sk-...` |
| Model | `gpt-4o-mini` |

## 🖼️ Screenshots

> **Note**: Add screenshots here after capturing them.
>
> - Pet on desktop
> - Chat panel
> - Settings window
> - Different skins (cat, ghost, robot)

## 🏗️ Architecture

```
DeskBuddy/
├── App/           # SwiftUI app entry, AppDelegate
├── Pet/           # SpriteKit pet rendering, animations
├── Window/        # NSPanel non-activating window management
├── AI/            # Chat engine, SSE streaming, API client
├── Voice/         # Speech recognition & TTS
├── Emotion/       # System monitoring, emotion state machine
├── UI/            # Settings panel, chat UI components
└── Assets/        # Pixel sprites, colors, animations
```

**Tech Stack:**
- **Swift** 5.9
- **SwiftUI** — UI framework
- **SpriteKit** — Pet animation engine
- **NSPanel** — Non-activating desktop window
- **Speech Framework** — Voice input
- **SSE** — Streaming AI responses

**Key Design:**
- `LSUIElement=true` — No dock icon, stays on desktop
- Non-activating NSPanel — Won't steal focus from other apps
- Real-time system monitoring via `ProcessInfo`

## 🛠️ Development

### Requirements
- macOS 13.0+
- Xcode 15.0+
- Swift 5.9

### Build
```bash
xcodebuild -project DeskBuddy.xcodeproj \
  -scheme DeskBuddy \
  -configuration Release \
  build
```

### Run Tests
```bash
xcodebuild -project DeskBuddy.xcodeproj \
  -scheme DeskBuddyTests \
  test
```

### Project Generation (XcodeGen)
If you use [XcodeGen](https://github.com/YonSwifty/XcodeGen):
```bash
xcodegen generate
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Guidelines:**
- Follow Swift naming conventions
- Keep pet animations smooth (60fps)
- Test on macOS 13+ and 14+
- Update docs for new features

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

```
Copyright (c) 2024 DeskBuddy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software...
```

## 🙏 Acknowledgments

- Pixel art inspired by classic desktop companions
- SpriteKit animation techniques from Apple samples
- OpenAI API community for streaming implementations

---

Made with 💙 for macOS

[Report Bug](https://github.com/yourusername/DeskBuddy/issues) · [Request Feature](https://github.com/yourusername/DeskBuddy/issues)