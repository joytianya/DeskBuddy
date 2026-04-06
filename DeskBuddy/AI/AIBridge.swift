// DeskBuddy/AI/AIBridge.swift
import Foundation
import SwiftUI

enum AIError: Error {
    case missingAPIKey
    case missingBaseURL
}

class AIBridge: ObservableObject {
    @Published var isLoading = false

    private let conversationStore = ConversationStore.shared
    private var config: ConfigStore { ConfigStore.shared }

    private var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }()

    func sendStream(userMessage: String, state: PetState, intimacyScore: Double) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    self.conversationStore.save(role: "user", content: userMessage)
                    let systemPrompt = SystemPromptBuilder.build(state: state, intimacyScore: intimacyScore)
                    let history = self.conversationStore.recentMessages(limit: 20)
                    let request = try self.buildRequest(system: systemPrompt, history: history)

                    let (bytes, response) = try await self.session.bytes(for: request)
                    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                        var raw = ""
                        for try await byte in bytes { raw += String(UnicodeScalar(byte)) }
                        let json = (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any]
                        let msg = (json?["error"] as? [String: Any])?["message"] as? String ?? "HTTP \(http.statusCode)"
                        throw NSError(domain: "AIBridge", code: http.statusCode,
                                      userInfo: [NSLocalizedDescriptionKey: msg])
                    }

                    var fullContent = ""
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonStr = String(line.dropFirst(6))
                        if jsonStr == "[DONE]" { break }
                        guard let data = jsonStr.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let chunk = delta["content"] as? String,
                              !chunk.isEmpty else { continue }
                        fullContent += chunk
                        continuation.yield(chunk)
                    }

                    self.conversationStore.save(role: "assistant", content: fullContent)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func buildRequest(system: String, history: [(role: String, content: String)]) throws -> URLRequest {
        let apiKey = config.apiKey
        let aiBaseURL = config.aiBaseURL
        let aiModel = config.aiModel

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
        let body: [String: Any] = ["model": model, "max_tokens": 512, "messages": messages, "stream": true]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}
