// DeskBuddy/UI/SettingsView.swift
import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("apiKey") var apiKey = ""
    @AppStorage("aiProvider") var aiProvider = "Claude"
    @AppStorage("voiceEnabled") var voiceEnabled = false
    @AppStorage("petScale") var petScale: Double = 4.0
    @AppStorage("selectedSkin") var selectedSkin = "cat-sheet"
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    let availableSkins = ["cat-sheet", "ghost-sheet", "robot-sheet"]

    var body: some View {
        Form {
            Section("AI 设置") {
                Picker("服务商", selection: $settings.aiProvider) {
                    Text("Claude").tag("Claude")
                    Text("OpenAI").tag("OpenAI")
                }
                .pickerStyle(.segmented)

                SecureField("API Key", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
            }

            Section("语音") {
                Toggle("启用语音", isOn: $settings.voiceEnabled)
            }

            Section("外观") {
                Picker("皮肤", selection: $settings.selectedSkin) {
                    ForEach(availableSkins, id: \.self) { skin in
                        Text(skin.replacingOccurrences(of: "-sheet", with: "").capitalized)
                            .tag(skin)
                    }
                }

                HStack {
                    Text("大小")
                    Slider(value: $settings.petScale, in: 2...8, step: 1)
                    Text("\(Int(settings.petScale))x")
                        .frame(width: 30)
                }
            }

            Section {
                Button("清除对话记录", role: .destructive) {
                    ConversationStore.shared.clearAll()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .padding()
    }
}
