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
        IMPORTANT: Always reply in the same language the user writes in. If the user writes in Chinese, reply in Chinese. If English, reply in English.
        """
    }
}
