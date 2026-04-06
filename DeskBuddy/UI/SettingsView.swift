// DeskBuddy/UI/SettingsView.swift
import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("apiKey") var apiKey = ""
    @AppStorage("aiProvider") var aiProvider = "OpenAI Compatible"
    @AppStorage("aiBaseURL") var aiBaseURL = "https://coding.dashscope.aliyuncs.com/v1"
    @AppStorage("aiModel") var aiModel = "glm-5"
    @AppStorage("voiceEnabled") var voiceEnabled = false
    @AppStorage("petScale") var petScale: Double = 4.0
    @AppStorage("selectedSkin") var selectedSkin = "cat-sheet"
    @AppStorage("petColorHex") var petColorHex = "#FFFFFF"
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    // Local draft — only committed on Save
    @State private var draftKey: String = ""
    @State private var draftBaseURL: String = ""
    @State private var draftModel: String = ""
    @State private var draftProvider: String = ""
    @State private var draftColorHex: String = ""
    @State private var pickedColor: Color = .white
    @State private var detectedModels: [String] = []
    @State private var detectStatus: DetectStatus = .idle
    @State private var pingStatus: PingStatus = .idle

    enum DetectStatus { case idle, loading, noModels, error(String) }
    enum PingStatus { case idle, loading, ok, fail(String) }

    private let providers = ["OpenAI Compatible", "Claude Compatible"]
    private let presetModelsByProvider: [String: [String]] = [
        "OpenAI Compatible": [
            "qwen3.5-plus", "qwen3-max-2026-01-23", "qwen3-coder-next", "qwen3-coder-plus",
            "glm-5", "glm-4.7",
            "kimi-k2.5",
            "MiniMax-M2.5",
            "deepseek-chat",
            "gpt-4o-mini", "gpt-4o",
        ],
        "Claude Compatible": [
            "claude-opus-4-6", "claude-sonnet-4-6", "claude-haiku-4-5-20251001", "claude-3-5-sonnet-20241022",
        ],
    ]
    private var presetModels: [String] { presetModelsByProvider[draftProvider] ?? [] }
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
                    Picker("服务商", selection: $draftProvider) {
                        ForEach(providers, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: draftProvider) { p in
                        // 切换服务商时自动填入默认 baseURL
                        if p == "Claude Compatible" {
                            if draftBaseURL.isEmpty || draftBaseURL == "https://coding.dashscope.aliyuncs.com/v1" {
                                draftBaseURL = "https://coding.dashscope.aliyuncs.com/apps/anthropic"
                            }
                        } else {
                            if draftBaseURL.isEmpty || draftBaseURL == "https://coding.dashscope.aliyuncs.com/apps/anthropic" {
                                draftBaseURL = "https://coding.dashscope.aliyuncs.com/v1"
                            }
                        }
                        // 切换时重置 model 为该 provider 的第一个预设
                        draftModel = presetModelsByProvider[p]?.first ?? ""
                    }

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
                            // Ping status indicator
                            switch pingStatus {
                            case .ok:
                                Label("连通", systemImage: "checkmark.circle.fill")
                                    .font(.caption).foregroundColor(.green)
                            case .fail(let msg):
                                Label(msg, systemImage: "xmark.circle.fill")
                                    .font(.caption).foregroundColor(.red)
                                    .lineLimit(1)
                            default:
                                EmptyView()
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
                                    Text("检测模型").font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                            .disabled(draftKey.isEmpty || draftBaseURL.isEmpty || {
                                if case .loading = detectStatus { return true }
                                return false
                            }())
                        }

                        // 检测状态提示
                        if case .noModels = detectStatus {
                            Text("未检测到模型列表，请手动输入").font(.caption).foregroundStyle(.secondary)
                        } else if case .error(let msg) = detectStatus {
                            Text(msg).font(.caption).foregroundColor(.red)
                        }

                        // 预设模型快选（检测到的在前，预设在后）
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(detectedModels, id: \.self) { m in
                                    modelChip(m, badge: true)
                                }
                                ForEach(presetModels.filter { !detectedModels.contains($0) }, id: \.self) { m in
                                    modelChip(m, badge: false)
                                }
                            }
                        }
                        // 自定义输入
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
                        Text("\(Int(settings.petScale))x")
                            .frame(width: 30)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("颜色叠加")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            ForEach(presetColors, id: \.0) { hex, color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle().stroke(draftColorHex == hex ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        draftColorHex = hex
                                        pickedColor = color
                                    }
                            }
                            ColorPicker("", selection: $pickedColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: pickedColor) { c in
                                    draftColorHex = c.toHex() ?? draftColorHex
                                }
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
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("保存") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 380)
        .onAppear { loadDraft() }
    }

    private func modelChip(_ m: String, badge: Bool) -> some View {
        HStack(spacing: 3) {
            if badge {
                Circle().fill(Color.green).frame(width: 5, height: 5)
            }
            Text(m).font(.system(size: 11))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(draftModel == m ? Color.accentColor : Color.secondary.opacity(0.15))
        .foregroundColor(draftModel == m ? .white : .primary)
        .cornerRadius(6)
        .onTapGesture { draftModel = m }
    }

    private func pingAPI() {
        pingStatus = .loading
        let base = draftBaseURL.hasSuffix("/") ? String(draftBaseURL.dropLast()) : draftBaseURL
        let isClaude = draftProvider == "Claude Compatible"

        Task {
            do {
                var req: URLRequest
                if isClaude {
                    guard let url = URL(string: "\(base)/messages") else {
                        await MainActor.run { pingStatus = .fail("URL 无效") }
                        return
                    }
                    req = URLRequest(url: url)
                    req.httpMethod = "POST"
                    req.setValue(draftKey, forHTTPHeaderField: "x-api-key")
                    req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let model = draftModel.isEmpty ? "claude-haiku-4-5-20251001" : draftModel
                    let body: [String: Any] = ["model": model, "max_tokens": 5,
                                               "messages": [["role": "user", "content": "hi"]]]
                    req.httpBody = try JSONSerialization.data(withJSONObject: body)
                } else {
                    guard let url = URL(string: "\(base)/chat/completions") else {
                        await MainActor.run { pingStatus = .fail("URL 无效") }
                        return
                    }
                    req = URLRequest(url: url)
                    req.httpMethod = "POST"
                    req.setValue("Bearer \(draftKey)", forHTTPHeaderField: "Authorization")
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let model = draftModel.isEmpty ? "gpt-4o-mini" : draftModel
                    let body: [String: Any] = ["model": model, "max_tokens": 5,
                                               "messages": [["role": "user", "content": "hi"]]]
                    req.httpBody = try JSONSerialization.data(withJSONObject: body)
                }
                req.timeoutInterval = 10

                let (data, response) = try await URLSession.shared.data(for: req)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                let errMsg = (json?["error"] as? [String: Any])?["message"] as? String

                await MainActor.run {
                    if code == 200 {
                        pingStatus = .ok
                    } else if let msg = errMsg {
                        // 有错误信息但能连上，说明 key/model 问题，不是网络问题
                        pingStatus = .fail(msg.prefix(30).description)
                    } else {
                        pingStatus = .fail("HTTP \(code)")
                    }
                }
            } catch {
                await MainActor.run { pingStatus = .fail("无法连接") }
            }
        }
    }

    private func detectModels() {
        detectStatus = .loading
        detectedModels = []
        let base = draftBaseURL.hasSuffix("/") ? String(draftBaseURL.dropLast()) : draftBaseURL
        guard let url = URL(string: "\(base)/models") else {
            detectStatus = .error("Base URL 无效")
            return
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(draftKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 10

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard statusCode == 200, !data.isEmpty else {
                    await MainActor.run { detectStatus = .noModels }
                    return
                }
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let models = (json?["data"] as? [[String: Any]])?.compactMap { $0["id"] as? String } ?? []
                await MainActor.run {
                    if models.isEmpty {
                        detectStatus = .noModels
                    } else {
                        detectedModels = models
                        detectStatus = .idle
                        if !models.contains(draftModel) { draftModel = models[0] }
                    }
                }
            } catch {
                await MainActor.run { detectStatus = .noModels }
            }
        }
    }

    private func loadDraft() {
        draftKey = settings.apiKey
        draftBaseURL = settings.aiBaseURL
        draftModel = settings.aiModel
        draftProvider = settings.aiProvider
        draftColorHex = settings.petColorHex
        pickedColor = Color(hex: draftColorHex) ?? .white
    }

    private func save() {
        settings.apiKey = draftKey
        settings.aiBaseURL = draftBaseURL
        settings.aiModel = draftModel
        settings.aiProvider = draftProvider
        settings.petColorHex = draftColorHex
        dismiss()
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
            Int(c.redComponent * 255),
            Int(c.greenComponent * 255),
            Int(c.blueComponent * 255))
    }
}
