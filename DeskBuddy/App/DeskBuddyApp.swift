// DeskBuddy/App/DeskBuddyApp.swift
import SwiftUI

@main
struct DeskBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No WindowGroup — window managed by AppDelegate
        Settings { EmptyView() }
    }
}
