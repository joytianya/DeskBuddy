// DeskBuddy/UI/ChatBubbleView.swift
import SwiftUI

struct ChatBubbleView: View {
    @ObservedObject var aiBridge: AIBridge
    @ObservedObject var emotionEngine: EmotionEngine
    @State private var inputText = ""
    @State private var messages: [(role: String, text: String)] = []
    @State private var isVisible = false
    @StateObject private var voiceInput = VoiceInput()
    @StateObject private var voiceOutput = VoiceOutput()
    let conversationStore = ConversationStore.shared
    var voiceEnabled: Bool = false

    // 动态计算聊天区域高度（基于消息数量）
    private var chatHeight: CGFloat {
        let minHeight: CGFloat = 120
        let maxHeight: CGFloat = 280
        let heightPerMessage: CGFloat = 25  // 每条消息约25px高度
        let calculatedHeight = minHeight + CGFloat(messages.count) * heightPerMessage
        return min(maxHeight, max(minHeight, calculatedHeight))
    }

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
                                            Text(msg.text.isEmpty ? "…" : msg.text)
                                                .padding(8)
                                                .background(Color.white.opacity(0.15))
                                                .foregroundColor(.white)
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
                                }
                                Color.clear.frame(height: 1).id("bottom")
                            }
                            .padding(8)
                        }
                        .onChange(of: messages.count) { _ in
                            withAnimation { proxy.scrollTo("bottom") }
                        }
                        .onChange(of: messages.last?.text) { _ in
                            proxy.scrollTo("bottom")
                        }
                    }
                    .frame(width: 260, height: chatHeight)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)

                    HStack {
                        TextField("说点什么...", text: $inputText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                            .onSubmit { sendMessage() }
                        if voiceEnabled {
                            Button(action: {
                                if voiceInput.isListening {
                                    voiceInput.stopListening()
                                    if !voiceInput.transcript.isEmpty {
                                        inputText = voiceInput.transcript
                                        voiceInput.transcript = ""
                                    }
                                } else {
                                    Task {
                                        let granted = await voiceInput.requestPermission()
                                        if granted { try? voiceInput.startListening() }
                                    }
                                }
                            }) {
                                Image(systemName: voiceInput.isListening ? "mic.fill" : "mic")
                                    .foregroundColor(voiceInput.isListening ? .red : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                        Button("发送") { sendMessage() }
                            .disabled(inputText.isEmpty || aiBridge.isLoading)
                    }
                    .frame(width: 260)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottomTrailing)))
            }

            // Invisible hit area kept for layout spacing only — tap handled via notification
            Color.clear
                .frame(width: 128, height: 128)
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleChat)) { _ in
            withAnimation(.spring()) { isVisible.toggle() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .hideChat)) { _ in
            if isVisible { withAnimation(.spring()) { isVisible = false } }
        }
        .onExitCommand {
            if isVisible { withAnimation(.spring()) { isVisible = false } }
        }
        .onAppear {
            // 加载最近10条对话历史，恢复上下文
            let history = conversationStore.recentMessages(limit: 10)
            messages = history.map { (role: $0.role, text: $0.content) }
        }
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        messages.append((role: "user", text: text))
        messages.append((role: "assistant", text: ""))
        let idx = messages.count - 1
        aiBridge.isLoading = true
        Task {
            do {
                var full = ""
                for try await chunk in aiBridge.sendStream(
                    userMessage: text,
                    state: emotionEngine.currentState,
                    intimacyScore: emotionEngine.intimacyScore
                ) {
                    full += chunk
                    await MainActor.run { messages[idx] = (role: "assistant", text: full) }
                }
                await MainActor.run {
                    if voiceEnabled { voiceOutput.speak(full) }
                    aiBridge.isLoading = false
                    emotionEngine.recordChat()
                }
            } catch {
                await MainActor.run {
                    messages[idx] = (role: "assistant", text: "出错了：\(error.localizedDescription)")
                    aiBridge.isLoading = false
                }
            }
        }
    }
}
