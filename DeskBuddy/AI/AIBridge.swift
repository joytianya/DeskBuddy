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
    @AppStorage("aiBaseURL") private var aiBaseURL = "https://api.openai.com/v1"
    @AppStorage("aiModel") private var aiModel = "gpt-4o-mini"

    private var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }()

    func send(userMessage: String, state: PetState, intimacyScore: Double) async throws -> String {
        store.save(role: "user", content: userMessage)
        let systemPrompt = SystemPromptBuilder.build(state: state, intimacyScore: intimacyScore)
        let history = store.recentMessages(limit: 20)
        let reply = try await callOpenAICompatible(system: systemPrompt, history: history)
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
        let model = aiModel.isEmpty ? "qwen-plus" : aiModel
        let body: [String: Any] = ["model": model, "max_tokens": 256, "messages": messages]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String
        if let errMsg = (json?["error"] as? [String: Any])?["message"] as? String {
            throw NSError(domain: "AIBridge", code: 0, userInfo: [NSLocalizedDescriptionKey: errMsg])
        }
        return content ?? "..."
    }
}
