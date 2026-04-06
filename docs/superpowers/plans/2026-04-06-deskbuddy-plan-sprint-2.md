# DeskBuddy — Sprint 2: AIBridge + 对话 UI

> **Owner:** dev-ai（AIBridge + CoreData）+ dev-ui（ChatBubbleView）并行  
> **周期:** Week 4–5  
> **目标:** 点击宠物弹出对话框，接 Claude/GPT API，宠物情绪影响回复风格

---

## Task 2.1: CoreData 对话持久化（dev-ai）

**Files:**
- Create: `DeskBuddy/Persistence/DeskBuddy.xcdatamodeld`
- Create: `DeskBuddy/AI/ConversationStore.swift`

- [ ] **Step 1: 创建 CoreData 模型**

  Xcode → New File → Data Model → 命名 `DeskBuddy`  
  添加 Entity `Message`，属性：
  - `id`: UUID
  - `role`: String（"user" 或 "assistant"）
  - `content`: String
  - `timestamp`: Date

- [ ] **Step 2: 创建 ConversationStore**

```swift
// DeskBuddy/AI/ConversationStore.swift
import CoreData
import Foundation

class ConversationStore {
    static let shared = ConversationStore()

    private let container: NSPersistentContainer

    /// inMemory: true 用于测试，避免污染生产数据库
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DeskBuddy")
        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        }
        container.loadPersistentStores { _, error in
            if let error { fatalError("CoreData load failed: \(error)") }
        }
    }

    var context: NSManagedObjectContext { container.viewContext }

    func save(role: String, content: String) {
        let msg = Message(context: context)
        msg.id = UUID()
        msg.role = role
        msg.content = content
        msg.timestamp = Date()
        try? context.save()
    }

    /// 返回最近 N 条消息，用于 AI 上下文
    func recentMessages(limit: Int = 20) -> [(role: String, content: String)] {
        let request = Message.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        let results = (try? context.fetch(request)) ?? []
        return results.reversed().map { (role: $0.role ?? "user", content: $0.content ?? "") }
    }

    func clearAll() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        let delete = NSBatchDeleteRequest(fetchRequest: request)
        try? context.execute(delete)
    }
}
```

- [ ] **Step 3: 写测试**

```swift
// DeskBuddyTests/AIBridgeTests.swift
import XCTest
@testable import DeskBuddy

final class AIBridgeTests: XCTestCase {
    // 每个测试用独立的 in-memory store，不污染生产数据库
    var store: ConversationStore!

    override func setUp() {
        super.setUp()
        store = ConversationStore(inMemory: true)
    }

    func test_conversationStore_saveAndRetrieve() {
        store.save(role: "user", content: "hello")
        store.save(role: "assistant", content: "hi there")
        let msgs = store.recentMessages(limit: 10)
        XCTAssertEqual(msgs.count, 2)
        XCTAssertEqual(msgs[0].role, "user")
        XCTAssertEqual(msgs[1].content, "hi there")
    }

    func test_conversationStore_limitWorks() {
        for i in 0..<25 { store.save(role: "user", content: "msg \(i)") }
        let msgs = store.recentMessages(limit: 20)
        XCTAssertEqual(msgs.count, 20)
    }
}
```

- [ ] **Step 4: 运行测试，确认通过**

- [ ] **Step 5: Commit**

```bash
git add DeskBuddy/Persistence/ DeskBuddy/AI/ConversationStore.swift DeskBuddyTests/AIBridgeTests.swift
git commit -m "feat: CoreData conversation store with limit and clear"
```

---

## Task 2.2: SystemPromptBuilder（dev-ai）

**Files:**
- Create: `DeskBuddy/AI/SystemPromptBuilder.swift`

- [ ] **Step 1: 写测试**

```swift
// 追加到 DeskBuddyTests/AIBridgeTests.swift
func test_systemPrompt_containsEmotionState() {
    let prompt = SystemPromptBuilder.build(state: .happy, intimacyScore: 0.8)
    XCTAssertTrue(prompt.contains("happy"))
    XCTAssertTrue(prompt.contains("intimate"))
}

func test_systemPrompt_anxious_mentionsStress() {
    let prompt = SystemPromptBuilder.build(state: .anxious, intimacyScore: 0.3)
    XCTAssertTrue(prompt.contains("anxious") || prompt.contains("stress"))
}
```

- [ ] **Step 2: 实现 SystemPromptBuilder**

```swift
// DeskBuddy/AI/SystemPromptBuilder.swift
import Foundation

struct SystemPromptBuilder {
    static func build(state: PetState, intimacyScore: Double) -> String {
        let emotionDesc: String
        switch state {
        case .happy:    emotionDesc = "happy and energetic"
        case .excited:  emotionDesc = "very excited and enthusiastic"
        case .sleepy:   emotionDesc = "sleepy and a bit slow"
        case .anxious:  emotionDesc = "anxious and stressed"
        case .bored:    emotionDesc = "bored and looking for fun"
        case .clingy:   emotionDesc = "clingy and affectionate"
        case .idle:     emotionDesc = "calm and relaxed"
        }

        let intimacyDesc: String
        switch intimacyScore {
        case 0.8...: intimacyDesc = "very intimate, like a close friend"
        case 0.5...: intimacyDesc = "friendly and familiar"
        case 0.2...: intimacyDesc = "polite but still getting to know each other"
        default:     intimacyDesc = "a bit shy, just met"
        }

        return """
        You are DeskBuddy, a pixel-art desktop pet living on the user's Mac.
        Current emotional state: \(emotionDesc).
        Relationship with user: \(intimacyDesc).
        Keep responses short (1-3 sentences), warm, and in character.
        Match your tone to your emotional state.
        """
    }
}
```

- [ ] **Step 3: 运行测试，确认通过**

- [ ] **Step 4: Commit**

```bash
git add DeskBuddy/AI/SystemPromptBuilder.swift
git commit -m "feat: SystemPromptBuilder injects emotion state into AI prompt"
```

---

## Task 2.3: AIBridge — API 调用（dev-ai）

**Files:**
- Create: `DeskBuddy/AI/AIBridge.swift`

- [ ] **Step 1: 实现 AIBridge**

```swift
// DeskBuddy/AI/AIBridge.swift
import Foundation

enum AIProvider: String, CaseIterable {
    case claude = "Claude"
    case openai = "OpenAI"
}

class AIBridge: ObservableObject {
    @Published var isLoading = false

    private let store = ConversationStore.shared
    var provider: AIProvider = .claude
    var apiKey: String = ""

    func send(userMessage: String, state: PetState, intimacyScore: Double) async throws -> String {
        store.save(role: "user", content: userMessage)
        let systemPrompt = SystemPromptBuilder.build(state: state, intimacyScore: intimacyScore)
        let history = store.recentMessages(limit: 20)

        let reply: String
        switch provider {
        case .claude:
            reply = try await callClaude(system: systemPrompt, history: history)
        case .openai:
            reply = try await callOpenAI(system: systemPrompt, history: history)
        }

        store.save(role: "assistant", content: reply)
        return reply
    }

    private var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private func callClaude(system: String, history: [(role: String, content: String)]) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages = history.map { ["role": $0.role, "content": $0.content] }
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 256,
            "system": system,
            "messages": messages
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = (json?["content"] as? [[String: Any]])?.first?["text"] as? String
        return content ?? "..."
    }

    private func callOpenAI(system: String, history: [(role: String, content: String)]) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var messages: [[String: String]] = [["role": "system", "content": system]]
        messages += history.map { ["role": $0.role, "content": $0.content] }
        let body: [String: Any] = ["model": "gpt-4o-mini", "max_tokens": 256, "messages": messages]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let content = (choices?.first?["message"] as? [String: String])?["content"]
        return content ?? "..."
    }
}

enum AIError: Error {
    case missingAPIKey
}
```

- [ ] **Step 2: Commit**

```bash
git add DeskBuddy/AI/AIBridge.swift
git commit -m "feat: AIBridge supports Claude and OpenAI with conversation history"
```

---

## Task 2.4: ChatBubbleView（dev-ui）

**Files:**
- Create: `DeskBuddy/UI/ChatBubbleView.swift`
- Modify: `DeskBuddy/Window/PetWindowView.swift`

- [ ] **Step 1: 创建 ChatBubbleView**

```swift
// DeskBuddy/UI/ChatBubbleView.swift
import SwiftUI

struct ChatBubbleView: View {
    @ObservedObject var aiBridge: AIBridge
    @ObservedObject var emotionEngine: EmotionEngine
    @State private var inputText = ""
    @State private var messages: [(role: String, text: String)] = []
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if isVisible {
                VStack(alignment: .leading, spacing: 8) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(messages.enumerated()), id: \.offset) { _, msg in
                                    HStack {
                                        if msg.role == "assistant" {
                                            Text(msg.text)
                                                .padding(8)
                                                .background(Color.white.opacity(0.9))
                                                .cornerRadius(10)
                                                .font(.system(size: 13))
                                            Spacer()
                                        } else {
                                            Spacer()
                                            Text(msg.text)
                                                .padding(8)
                                                .background(Color.blue.opacity(0.8))
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                                .font(.system(size: 13))
                                        }
                                    }
                                    .id(msg.role + "\(messages.count)")
                                }
                            }
                            .padding(8)
                        }
                        .frame(width: 260, height: 180)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                    }

                    HStack {
                        TextField("说点什么...", text: $inputText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                            .onSubmit { sendMessage() }
                        Button("发送") { sendMessage() }
                            .disabled(inputText.isEmpty || aiBridge.isLoading)
                    }
                    .frame(width: 260)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottomTrailing)))
            }

            // 宠物点击区域
            Rectangle()
                .fill(Color.clear)
                .frame(width: 128, height: 128)
                .contentShape(Rectangle())
                .onTapGesture { withAnimation(.spring()) { isVisible.toggle() } }
        }
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        messages.append((role: "user", text: text))
        aiBridge.isLoading = true
        Task {
            do {
                let reply = try await aiBridge.send(
                    userMessage: text,
                    state: emotionEngine.currentState,
                    intimacyScore: 0.5 // TODO: 接真实 intimacy
                )
                await MainActor.run {
                    messages.append((role: "assistant", text: reply))
                    aiBridge.isLoading = false
                    emotionEngine.recordChat()
                }
            } catch {
                await MainActor.run {
                    messages.append((role: "assistant", text: "出错了，检查一下 API Key？"))
                    aiBridge.isLoading = false
                }
            }
        }
    }
}
```

- [ ] **Step 2: 在 PetWindowView 中集成 ChatBubbleView**

```swift
// 修改 DeskBuddy/Window/PetWindowView.swift
import SwiftUI
import SpriteKit

struct PetWindowView: View {
    let engine: PetEngine
    @ObservedObject var emotionEngine: EmotionEngine
    @StateObject private var aiBridge = AIBridge()

    init(emotionEngine: EmotionEngine) {
        let scene = PetEngine(size: CGSize(width: 128, height: 128))
        scene.scaleMode = .aspectFit
        self.engine = scene
        self.emotionEngine = emotionEngine
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SpriteView(scene: engine, options: [.allowsTransparency])
                .frame(width: 128, height: 128)
                .background(Color.clear)

            ChatBubbleView(aiBridge: aiBridge, emotionEngine: emotionEngine)
        }
        .frame(width: 400, height: 400)
    }
}
```

- [ ] **Step 3: 运行，点击宠物弹出对话框，输入文字发送，收到 AI 回复**

  需要在 SettingsView（Sprint 3）填入 API Key 前，先在 AIBridge 中临时硬编码 Key 测试

- [ ] **Step 4: Commit**

```bash
git add DeskBuddy/UI/ChatBubbleView.swift DeskBuddy/Window/PetWindowView.swift
git commit -m "feat: ChatBubbleView with AI chat, tap pet to toggle"
```

---

## Sprint 2 完成标准

- [ ] 点击宠物弹出对话框
- [ ] 发送文字，收到 AI 回复（Claude 或 OpenAI）
- [ ] 对话历史持久化，重启 app 后仍保留
- [ ] 宠物情绪影响 AI 回复风格（通过 system prompt）
- [ ] 所有测试通过
