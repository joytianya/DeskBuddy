// DeskBuddy/Emotion/TimeSignal.swift
import Foundation

struct TimeSignal {
    static func score(hour: Int) -> Double {
        switch hour {
        case 6..<9:   return 0.3
        case 9..<12:  return 0.9
        case 12..<14: return 0.4
        case 14..<18: return 0.6
        case 18..<22: return 0.75
        case 22..<24: return 0.3
        case 0..<3:   return 0.2
        case 3..<6:   return 0.1
        default:      return 0.5
        }
    }

    static func currentScore() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())
        return score(hour: hour)
    }
}
