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
    var voiceEnabled: Bool = false

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
                    .frame(width: 260, height: 180)
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
        .onExitCommand {
            if isVisible { withAnimation(.spring()) { isVisible = false } }
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
                    intimacyScore: 0.5
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
