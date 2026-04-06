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
                            }
                        }
                        .padding(8)
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
                    intimacyScore: 0.5
                )
                await MainActor.run {
                    messages.append((role: "assistant", text: reply))
                    if voiceEnabled { voiceOutput.speak(reply) }
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
