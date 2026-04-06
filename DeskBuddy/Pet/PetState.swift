// DeskBuddy/Pet/PetState.swift
import Foundation

enum PetState: Int, CaseIterable {
    case idle = 0
    case happy = 1
    case sleepy = 2
    case anxious = 3
    case bored = 4
    case excited = 5
    case clingy = 6

    var frameCount: Int { 6 }
    var rowIndex: Int { rawValue }
}
