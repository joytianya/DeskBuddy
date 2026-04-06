// DeskBuddy/AI/AIBridge.swift
import Foundation

enum AIProvider: String, CaseIterable {
    case claude = "Claude"
    case openai = "OpenAI"
}

enum AIError: Error {
    case missingAPIKey
}

class AIBridge: ObservableObject {
    @Published var isLoading = false

    private let store = ConversationStore.shared
    var provider: AIProvider = .claude
    var apiKey: String = ""

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
        switch provider {
        case .claude:
            reply = try await callClaude(system: systemPrompt, history: history)
        case .openai:
            reply = try await callOpenAI(system: systemPrompt, history: history)
        }

        store.save(role: "assistant", content: reply)
        return reply
    }

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
