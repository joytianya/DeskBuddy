// DeskBuddy/UI/SettingsView.swift
import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("apiKey") var apiKey = "sk-83d380f5e8294b0596e832479a1c248c"
    @AppStorage("aiBaseURL") var aiBaseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    @AppStorage("aiModel") var aiModel = "qwen3.5-plus"
    @AppStorage("voiceEnabled") var voiceEnabled = false
    @AppStorage("petScale") var petScale: Double = 4.0
    @AppStorage("selectedSkin") var selectedSkin = "cat-sheet"
    @AppStorage("petColorHex") var petColorHex = "#FFFFFF"
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    var onDismiss: (() -> Void)? = nil

    @State private var draftKey: String = ""
    @State private var draftBaseURL: String = ""
    @State private var draftModel: String = ""
    @State private var draftColorHex: String = ""
    @State private var pickedColor: Color = .white
    @State private var detectStatus: DetectStatus = .idle
    @State private var pingStatus: PingStatus = .idle

    enum DetectStatus { case idle, loading, ok, fail(String) }
    enum PingStatus { case idle, loading, ok, fail(String) }

    private let presetModels = [
        "qwen-plus", "qwen-max", "qwen-turbo",
        "qwen3-max-2026-01-23", "qwen3-coder-plus",
        "glm-5", "glm-4.7",
        "kimi-k2.5", "MiniMax-M2.5",
        "deepseek-chat",
    ]
    private let presetColors: [(String, Color)] = [
        ("#FFFFFF", .white),
        ("#FFD6E0", Color(red: 1, green: 0.84, blue: 0.88)),
        ("#D6F0FF", Color(red: 0.84, green: 0.94, blue: 1)),
        ("#D6FFD6", Color(red: 0.84, green: 1, blue: 0.84)),
        ("#FFF3D6", Color(red: 1, green: 0.95, blue: 0.84)),
        ("#E8D6FF", Color(red: 0.91, green: 0.84, blue: 1)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("AI 设置") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Base URL").font(.caption).foregroundStyle(.secondary)
                        TextField("", text: $draftBaseURL)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("API Key").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            switch pingStatus {
                            case .ok:
                                Label("连通", systemImage: "checkmark.circle.fill")
                                    .font(.caption).foregroundColor(.green)
                            case .fail(let msg):
                                Label(msg, systemImage: "xmark.circle.fill")
                                    .font(.caption).foregroundColor(.red).lineLimit(1)
                            default: EmptyView()
                            }
                            Button(action: pingAPI) {
                                if case .loading = pingStatus {
                                    ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
                                } else {
                                    Text("测试连接").font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                            .disabled(draftKey.isEmpty || draftBaseURL.isEmpty || {
                                if case .loading = pingStatus { return true }
                                return false
                            }())
                        }
                        SecureField("输入 API Key", text: $draftKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Model").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Button(action: detectModels) {
                                if case .loading = detectStatus {
                                    ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
                                } else {
                                    Text("测试模型").font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                            .disabled(draftKey.isEmpty || draftBaseURL.isEmpty || draftModel.isEmpty || {
                                if case .loading = detectStatus { return true }
                                return false
                            }())
                        }
                        switch detectStatus {
                        case .ok:
                            Label("模型可用", systemImage: "checkmark.circle.fill")
                                .font(.caption).foregroundColor(.green)
                        case .fail(let msg):
                            Label(msg, systemImage: "xmark.circle.fill")
                                .font(.caption).foregroundColor(.red).lineLimit(2)
                        default: EmptyView()
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(presetModels, id: \.self) { modelChip($0, badge: false) }
                            }
                        }
                        TextField("自定义 model 名称", text: $draftModel)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                    }
                }

                Section("外观") {
                    Picker("皮肤", selection: $settings.selectedSkin) {
                        Text("Cat").tag("cat-sheet")
                        Text("Ghost").tag("ghost-sheet")
                        Text("Robot").tag("robot-sheet")
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("大小")
                        Slider(value: $settings.petScale, in: 2...8, step: 1)
                        Text("\(Int(settings.petScale))x").frame(width: 30)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("颜色叠加").font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            ForEach(presetColors, id: \.0) { hex, color in
                                Circle().fill(color).frame(width: 24, height: 24)
                                    .overlay(Circle().stroke(draftColorHex == hex ? Color.accentColor : Color.clear, lineWidth: 2))
                                    .onTapGesture { draftColorHex = hex; pickedColor = color }
                            }
                            ColorPicker("", selection: $pickedColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: pickedColor) { draftColorHex = $0.toHex() ?? draftColorHex }
                        }
                    }
                }

                Section("语音") {
                    Toggle("启用语音", isOn: $settings.voiceEnabled)
                }

                Section {
                    Button("清除对话记录", role: .destructive) {
                        ConversationStore.shared.clearAll()
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("取消") { doClose() }.keyboardShortcut(.cancelAction)
                Button("保存") { save() }.keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 380)
        .onAppear { loadDraft() }
    }

    private func modelChip(_ m: String, badge: Bool = false) -> some View {
        HStack(spacing: 3) {
            if badge { Circle().fill(Color.green).frame(width: 5, height: 5) }
            Text(m).font(.system(size: 11))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(draftModel == m ? Color.accentColor : Color.secondary.opacity(0.15))
        .foregroundColor(draftModel == m ? .white : .primary)
        .cornerRadius(6)
        .onTapGesture { draftModel = m }
    }

    private func doClose() {
        if let onDismiss { onDismiss() } else { dismiss() }
    }

    private func pingAPI() {
        pingStatus = .loading
        let base = draftBaseURL.hasSuffix("/") ? String(draftBaseURL.dropLast()) : draftBaseURL
        guard let url = URL(string: "\(base)/chat/completions") else {
            pingStatus = .fail("URL 无效"); return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(draftKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 10
        let model = draftModel.isEmpty ? "qwen-plus" : draftModel
        let body: [String: Any] = ["model": model, "max_tokens": 5,
                                   "messages": [["role": "user", "content": "hi"]]]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                let errMsg = (json?["error"] as? [String: Any])?["message"] as? String
                await MainActor.run {
                    if code == 200 { pingStatus = .ok }
                    else if let msg = errMsg { pingStatus = .fail(String(msg.prefix(30))) }
                    else { pingStatus = .fail("HTTP \(code)") }
                }
            } catch {
                await MainActor.run { pingStatus = .fail("无法连接") }
            }
        }
    }

    private func detectModels() {
        detectStatus = .loading
        let base = draftBaseURL.hasSuffix("/") ? String(draftBaseURL.dropLast()) : draftBaseURL
        guard let url = URL(string: "\(base)/chat/completions") else {
            detectStatus = .fail("URL 无效"); return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(draftKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 15
        let body: [String: Any] = [
            "model": draftModel,
            "max_tokens": 10,
            "messages": [["role": "user", "content": "hi"]]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                let errMsg = (json?["error"] as? [String: Any])?["message"] as? String
                await MainActor.run {
                    if code == 200 { detectStatus = .ok }
                    else if let msg = errMsg { detectStatus = .fail(String(msg.prefix(50))) }
                    else { detectStatus = .fail("HTTP \(code)") }
                }
            } catch {
                await MainActor.run { detectStatus = .fail("无法连接") }
            }
        }
    }

    private func loadDraft() {
        draftKey = settings.apiKey
        draftBaseURL = settings.aiBaseURL
        draftModel = settings.aiModel
        draftColorHex = settings.petColorHex
        pickedColor = Color(hex: draftColorHex) ?? .white
    }

    private func save() {
        settings.apiKey = draftKey
        settings.aiBaseURL = draftBaseURL
        settings.aiModel = draftModel
        settings.petColorHex = draftColorHex
        doClose()
    }
}

// MARK: - Color helpers

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return nil }
        self.init(
            red: Double((val >> 16) & 0xFF) / 255,
            green: Double((val >> 8) & 0xFF) / 255,
            blue: Double(val & 0xFF) / 255
        )
    }

    func toHex() -> String? {
        guard let c = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        return String(format: "#%02X%02X%02X",
            Int(c.redComponent * 255), Int(c.greenComponent * 255), Int(c.blueComponent * 255))
    }
}
