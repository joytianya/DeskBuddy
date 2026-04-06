// DeskBuddy/AI/AIBridge.swift
import Foundation
import SwiftUI

enum AIError: Error {
    case missingAPIKey
    case missingBaseURL
}

class AIBridge: ObservableObject {
    @Published var isLoading = false

    private let store = ConversationStore.shared
    @AppStorage("apiKey") var apiKey = ""
    @AppStorage("aiProvider") private var providerString = "OpenAI Compatible"
    @AppStorage("aiBaseURL") private var aiBaseURL = "https://coding.dashscope.aliyuncs.com/v1"
    @AppStorage("aiModel") private var aiModel = "qwen-plus"

    private var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    func send(userMessage: String, state: PetState, intimacyScore: Double) async throws -> String {
        store.save(role: "user", content: userMessage)
        let systemPrompt = SystemPromptBuilder.build(state: state, intimacyScore: intimacyScore)
        let history = store.recentMessages(limit: 20)

        let reply: String
        if providerString == "Claude Compatible" {
            reply = try await callClaude(system: systemPrompt, history: history)
        } else {
            // OpenAI Compatible — works for OpenAI, DashScope, DeepSeek, etc.
            reply = try await callOpenAICompatible(system: systemPrompt, history: history)
        }

        store.save(role: "assistant", content: reply)
        return reply
    }

    private func callOpenAICompatible(system: String, history: [(role: String, content: String)]) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }
        let base = aiBaseURL.hasSuffix("/") ? String(aiBaseURL.dropLast()) : aiBaseURL
        guard let url = URL(string: "\(base)/chat/completions") else { throw AIError.missingBaseURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var messages: [[String: String]] = [["role": "system", "content": system]]
        messages += history.map { ["role": $0.role, "content": $0.content] }
        let model = aiModel.isEmpty ? "gpt-4o-mini" : aiModel
        let body: [String: Any] = ["model": model, "max_tokens": 256, "messages": messages]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let content = (choices?.first?["message"] as? [String: String])?["content"]
        return content ?? "..."
    }

    private func callClaude(system: String, history: [(role: String, content: String)]) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }
        let base = aiBaseURL.isEmpty ? "https://api.anthropic.com/v1" : aiBaseURL
        guard let url = URL(string: "\(base)/messages") else { throw AIError.missingBaseURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages = history.map { ["role": $0.role, "content": $0.content] }
        let model = aiModel.isEmpty ? "claude-haiku-4-5-20251001" : aiModel
        let body: [String: Any] = [
            "model": model,
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
}
