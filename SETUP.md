# DeskBuddy — Xcode Project Setup

The `.xcodeproj` bundle cannot be generated from the command line without Xcode. Follow these steps once to wire everything up.

## One-time manual step

1. Open Xcode.
2. Choose **File > New > Project…**
3. Select **macOS > App** and click **Next**.
4. Fill in the fields:
   - Product Name: `DeskBuddy`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Uncheck "Include Tests" (add later if needed)
5. When prompted for a location, navigate to `/Users/matrix/projects/dev/DeskBuddy` and click **Create**.
   - Xcode will create `DeskBuddy.xcodeproj` inside that directory.
   - **Do not** let Xcode create a new subdirectory — save directly into the existing folder.

## Add existing source files

After the project is created, Xcode will have generated its own `ContentView.swift` and `DeskBuddyApp.swift` stubs. Replace them with the files already in the repo:

1. In the Xcode Project Navigator, delete the generated `ContentView.swift` (move to Trash).
2. Delete the generated `DeskBuddyApp.swift` stub.
3. Right-click the `DeskBuddy` group in the navigator and choose **Add Files to "DeskBuddy"…**
4. Select `DeskBuddy/App/DeskBuddyApp.swift` and `DeskBuddy/App/AppDelegate.swift`, then click **Add**.

## Build settings to verify

- Deployment Target: **macOS 13.0** or later
- Signing: set your Team in **Signing & Capabilities**

## After setup

Run `git add DeskBuddy.xcodeproj` and commit so the project file is tracked.
