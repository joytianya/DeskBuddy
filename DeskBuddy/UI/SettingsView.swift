// DeskBuddy/UI/SettingsView.swift
import SwiftUI

/// AppSettings 包装 ConfigStore，提供 ObservableObject
class AppSettings: ObservableObject {
    @Published var apiKey: String {
        didSet { ConfigStore.shared.apiKey = apiKey }
    }
    @Published var aiBaseURL: String {
        didSet { ConfigStore.shared.aiBaseURL = aiBaseURL }
    }
    @Published var aiModel: String {
        didSet { ConfigStore.shared.aiModel = aiModel }
    }
    @Published var voiceEnabled: Bool {
        didSet { ConfigStore.shared.voiceEnabled = voiceEnabled }
    }
    @Published var petScale: Double {
        didSet { ConfigStore.shared.petScale = petScale }
    }
    @Published var selectedSkin: String {
        didSet { ConfigStore.shared.selectedSkin = selectedSkin }
    }
    @Published var petColorHex: String {
        didSet { ConfigStore.shared.petColorHex = petColorHex }
    }
    @Published var renderMode: String {
        didSet { ConfigStore.shared.renderMode = renderMode }
    }

    init() {
        let store = ConfigStore.shared
        // 迁移旧的 UserDefaults 配置
        store.migrateFromUserDefaults()
        // 初始化
        apiKey = store.apiKey
        aiBaseURL = store.aiBaseURL
        aiModel = store.aiModel
        voiceEnabled = store.voiceEnabled
        petScale = store.petScale
        selectedSkin = store.selectedSkin
        petColorHex = store.petColorHex
        renderMode = store.renderMode
    }
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

    // 辅助函数：创建颜色选择圆圈，避免编译器类型检查超时
    private func colorCircle(hex: String, color: Color) -> some View {
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
                    // 渲染模式切换
                    Picker("渲染模式", selection: $settings.renderMode) {
                        Text("3D 小狗").tag("3d")
                        Text("2D 像素").tag("2d")
                    }
                    .pickerStyle(.segmented)

                    // 2D模式才显示皮肤选项
                    if settings.renderMode == "2d" {
                        Picker("皮肤", selection: $settings.selectedSkin) {
                            Text("Cat").tag("cat-sheet")
                            Text("Ghost").tag("ghost-sheet")
                            Text("Robot").tag("robot-sheet")
                        }
                        .pickerStyle(.segmented)
                    }

                    HStack {
                        Text("大小")
                        Slider(value: $settings.petScale, in: 2...8, step: 1)
                        Text("\(Int(settings.petScale))x").frame(width: 30)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(settings.renderMode == "3d" ? "小狗颜色" : "颜色叠加").font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            ForEach(presetColors, id: \.0) { hex, color in
                                colorCircle(hex: hex, color: color)
                            }
                            ColorPicker("", selection: $pickedColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: pickedColor, perform: { newValue in
                                    draftColorHex = newValue.toHex() ?? draftColorHex
                                })
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

    private func selectColor(hex: String, color: Color) {
        draftColorHex = hex
        pickedColor = color
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
