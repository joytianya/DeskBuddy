# DeskBuddy — Sprint 3: 语音 + 设置面板 + 打包

> **Owner:** dev-ai（VoiceModule）+ dev-ui（SettingsView）+ dev-qa（打包/权限）并行  
> **周期:** Week 6  
> **目标:** 语音可选开关，设置面板完整，app 可分发

---

## Task 3.0: 补全 SystemSignal 真实数据接入（dev-core）

> 闭环 Sprint 1 中的两个 TODO：真实内存压力 + 真实 idle 时间

**Files:**
- Modify: `DeskBuddy/Emotion/SystemSignal.swift`
- Modify: `DeskBuddy/Emotion/EmotionEngine.swift`

- [ ] **Step 1: 实现真实内存压力读取（IOKit）**

```swift
// 追加到 DeskBuddy/Emotion/SystemSignal.swift
import IOKit

static func currentMemoryPressure() -> Double {
    // macOS 提供 memory_pressure 通知，0=normal, 1=warning, 2=critical
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
    let result = withUnsafeMutablePointer(to: &stats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
        }
    }
    guard result == KERN_SUCCESS else { return 0.3 }
    let total = Double(stats.free_count + stats.active_count + stats.inactive_count + stats.wire_count)
    let used = Double(stats.active_count + stats.wire_count)
    return total > 0 ? used / total : 0.3
}
```

- [ ] **Step 2: 实现真实 idle 时间读取（CGEventSource）**

```swift
// 追加到 DeskBuddy/Emotion/SystemSignal.swift
import CoreGraphics

static func currentIdleMinutes() -> Int {
    let idleSeconds = CGEventSource.secondsSinceLastEventType(
        .combinedSessionState,
        eventType: CGEventType(rawValue: ~0)! // 任意事件
    )
    return Int(idleSeconds / 60)
}
```

- [ ] **Step 3: 更新 EmotionEngine.update() 使用真实数据**

```swift
// 修改 DeskBuddy/Emotion/EmotionEngine.swift 中的 update()
private func update() {
    let t = TimeSignal.currentScore()
    let i = intimacy.score
    let s = SystemSignal.score(
        cpuUsage: SystemSignal.currentCPUUsage(),
        memoryPressure: SystemSignal.currentMemoryPressure(), // 真实内存
        idleMinutes: SystemSignal.currentIdleMinutes()        // 真实 idle
    )
    currentState = computeState(timeScore: t, intimacyScore: i, systemScore: s)
}
```

- [ ] **Step 4: 运行所有 EmotionEngine 测试，确认通过**

  Cmd+U，预期：全部通过（SystemSignal 测试用注入参数，不受真实系统状态影响）

- [ ] **Step 5: Commit**

```bash
git add DeskBuddy/Emotion/SystemSignal.swift DeskBuddy/Emotion/EmotionEngine.swift
git commit -m "feat: SystemSignal real memory pressure and idle time via IOKit/CGEvent"
```

---

## Task 3.1: VoiceInput — Apple Speech STT（dev-ai）

**Files:**
- Create: `DeskBuddy/Voice/VoiceInput.swift`

- [ ] **Step 1: 在 Info.plist 添加麦克风权限**

  Xcode → Target → Info → 添加：
  - `NSMicrophoneUsageDescription`: "DeskBuddy 需要麦克风权限来接收语音输入"
  - `NSSpeechRecognitionUsageDescription`: "DeskBuddy 需要语音识别权限来理解你说的话"

- [ ] **Step 2: 实现 VoiceInput**

```swift
// DeskBuddy/Voice/VoiceInput.swift
import Speech
import AVFoundation
import Combine

class VoiceInput: ObservableObject {
    @Published var transcript = ""
    @Published var isListening = false

    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let engine = AVAudioEngine()

    func requestPermission() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    func startListening(locale: Locale = .current) throws {
        recognizer = SFSpeechRecognizer(locale: locale)
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let node = engine.inputNode
        let format = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        try engine.start()
        isListening = true

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                DispatchQueue.main.async { self?.transcript = result.bestTranscription.formattedString }
            }
            if error != nil || result?.isFinal == true { self?.stopListening() }
        }
    }

    func stopListening() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        isListening = false
    }
}
```

- [ ] **Step 3: 在 ChatBubbleView 添加语音按钮（仅当 voiceEnabled 时显示）**

```swift
// 追加到 ChatBubbleView.swift 的 HStack 中
if voiceEnabled {
    Button(action: toggleVoice) {
        Image(systemName: voiceInput.isListening ? "mic.fill" : "mic")
            .foregroundColor(voiceInput.isListening ? .red : .primary)
    }
    .buttonStyle(.plain)
}
```

- [ ] **Step 4: Commit**

```bash
git add DeskBuddy/Voice/VoiceInput.swift DeskBuddy/UI/ChatBubbleView.swift
git commit -m "feat: VoiceInput Apple Speech STT, mic button in chat"
```

---

## Task 3.2: VoiceOutput — Apple TTS（dev-ai）

**Files:**
- Create: `DeskBuddy/Voice/VoiceOutput.swift`

- [ ] **Step 1: 实现 VoiceOutput**

```swift
// DeskBuddy/Voice/VoiceOutput.swift
import AVFoundation

class VoiceOutput: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, rate: Float = 0.5, pitch: Float = 1.2) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
        synthesizer.speak(utterance)
    }

    func stop() { synthesizer.stopSpeaking(at: .immediate) }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}
```

- [ ] **Step 2: 在 ChatBubbleView 中，AI 回复后自动朗读（voiceEnabled 时）**

```swift
// 在 sendMessage() 的 reply 处理中追加
if voiceEnabled {
    voiceOutput.speak(reply)
}
```

- [ ] **Step 3: Commit**

```bash
git add DeskBuddy/Voice/VoiceOutput.swift
git commit -m "feat: VoiceOutput Apple TTS, auto-speak AI replies when voice enabled"
```

---

## Task 3.3: SettingsView（dev-ui）

**Files:**
- Create: `DeskBuddy/UI/SettingsView.swift`

- [ ] **Step 1: 实现 SettingsView**

```swift
// DeskBuddy/UI/SettingsView.swift
import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("apiKey") var apiKey = ""
    @AppStorage("aiProvider") var aiProvider = "Claude"
    @AppStorage("voiceEnabled") var voiceEnabled = false
    @AppStorage("petScale") var petScale: Double = 4.0
    @AppStorage("selectedSkin") var selectedSkin = "cat-sheet"
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    let availableSkins = ["cat-sheet", "ghost-sheet", "robot-sheet"]

    var body: some View {
        Form {
            Section("AI 设置") {
                Picker("服务商", selection: $settings.aiProvider) {
                    Text("Claude").tag("Claude")
                    Text("OpenAI").tag("OpenAI")
                }
                .pickerStyle(.segmented)

                SecureField("API Key", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
            }

            Section("语音") {
                Toggle("启用语音", isOn: $settings.voiceEnabled)
            }

            Section("外观") {
                Picker("皮肤", selection: $settings.selectedSkin) {
                    ForEach(availableSkins, id: \.self) { skin in
                        Text(skin.replacingOccurrences(of: "-sheet", with: "").capitalized)
                            .tag(skin)
                    }
                }

                HStack {
                    Text("大小")
                    Slider(value: $settings.petScale, in: 2...8, step: 1)
                    Text("\(Int(settings.petScale))x")
                        .frame(width: 30)
                }
            }

            Section {
                Button("清除对话记录", role: .destructive) {
                    ConversationStore.shared.clearAll()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .padding()
    }
}
```

- [ ] **Step 2: 在右键菜单中打开设置窗口**

```swift
// DeskBuddy/UI/ContextMenuView.swift
import SwiftUI
import AppKit

struct ContextMenuView: View {
    let settings: AppSettings
    let onQuit: () -> Void
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            Button("设置") { showSettings = true }
                .sheet(isPresented: $showSettings) {
                    SettingsView(settings: settings)
                }
            Divider()
            Button("退出", role: .destructive) { onQuit() }
        }
    }
}
```

- [ ] **Step 3: 在 PetWindowView 添加右键手势**

```swift
// 在 PetWindowView body 中的 SpriteView 上追加
.contextMenu {
    Button("设置") { showSettings = true }
    Button("退出", role: .destructive) { NSApp.terminate(nil) }
}
```

- [ ] **Step 4: Commit**

```bash
git add DeskBuddy/UI/SettingsView.swift DeskBuddy/UI/ContextMenuView.swift
git commit -m "feat: SettingsView with API key, skin picker, voice toggle, scale"
```

---

## Task 3.4: 打包与权限（dev-qa）

**Files:**
- Modify: `DeskBuddy/DeskBuddy.entitlements`
- Modify: `Info.plist`

- [ ] **Step 1: 配置 entitlements**

  Xcode → Target → Signing & Capabilities → 添加：
  - App Sandbox: 开启
  - Network: Outgoing Connections（访问 AI API）
  - Hardware: Microphone（语音输入）

- [ ] **Step 2: 验证 macOS 13+ 最低版本**

  Target → Deployment Info → macOS 13.0

- [ ] **Step 3: 测试权限申请流程**

  首次运行时：
  - 麦克风权限弹窗出现（点击语音按钮时触发）
  - 语音识别权限弹窗出现
  - 辅助功能权限（如需要）

- [ ] **Step 4: Archive 打包**

  Xcode → Product → Archive  
  预期：Archive 成功，无 code signing 错误

- [ ] **Step 5: 导出 .app 并测试**

  Organizer → Distribute App → Copy App  
  在另一个目录运行导出的 .app，确认功能正常

- [ ] **Step 6: Commit**

```bash
git add DeskBuddy/DeskBuddy.entitlements
git commit -m "chore: configure entitlements, sandbox, macOS 13 min target"
```

---

## Sprint 3 完成标准

- [ ] 语音输入/输出可在设置中开关
- [ ] 设置面板可配置 API Key、皮肤、大小、语音
- [ ] 右键菜单打开设置、退出
- [ ] Archive 打包成功，导出 .app 可独立运行
- [ ] 所有权限申请流程正常
- [ ] 全部测试通过

---

## MVP 完成标准（所有 Sprint）

- [ ] 像素宠物悬浮在屏幕上，可拖拽，可缩放
- [ ] 情绪系统运行，宠物根据时间/互动/系统状态切换动画
- [ ] 点击宠物弹出对话框，AI 回复风格匹配情绪
- [ ] 语音输入/输出可选
- [ ] 3 套内置皮肤可切换
- [ ] 设置面板完整
- [ ] 打包为 .app 可分发
