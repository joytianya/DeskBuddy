// DeskBuddy/Config/ConfigStore.swift
import Foundation
import SwiftUI

/// 配置存储：保存到 ~/.deskbuddy/config.json
class ConfigStore: ObservableObject {
    static let shared = ConfigStore()

    let configURL: URL

    @Published var apiKey: String = "" {
        didSet { save() }
    }
    @Published var aiBaseURL: String = "https://api.openai.com/v1" {
        didSet { save() }
    }
    @Published var aiModel: String = "gpt-4o-mini" {
        didSet { save() }
    }
    @Published var voiceEnabled: Bool = false {
        didSet { save() }
    }
    @Published var petScale: Double = 4.0 {
        didSet { save() }
    }
    @Published var selectedSkin: String = "cat-sheet" {
        didSet { save() }
    }
    @Published var petColorHex: String = "#FFFFFF" {
        didSet { save() }
    }

    private init() {
        // 配置目录: ~/.deskbuddy/
        let deskbuddyDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".deskbuddy", isDirectory: true)
        configURL = deskbuddyDir.appendingPathComponent("config.json")

        // 创建目录（如果不存在）
        try? FileManager.default.createDirectory(at: deskbuddyDir, withIntermediateDirectories: true)

        // 加载配置
        load()
    }

    // MARK: - Codable Config

    private struct Config: Codable {
        var apiKey: String = ""
        var aiBaseURL: String = "https://api.openai.com/v1"
        var aiModel: String = "gpt-4o-mini"
        var voiceEnabled: Bool = false
        var petScale: Double = 4.0
        var selectedSkin: String = "cat-sheet"
        var petColorHex: String = "#FFFFFF"
    }

    // MARK: - Load/Save

    private func load() {
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            // 文件不存在或解析失败，使用默认值
            return
        }

        apiKey = config.apiKey
        aiBaseURL = config.aiBaseURL
        aiModel = config.aiModel
        voiceEnabled = config.voiceEnabled
        petScale = config.petScale
        selectedSkin = config.selectedSkin
        petColorHex = config.petColorHex
    }

    private var saveDebounce: DispatchWorkItem?

    private func save() {
        // 防抖：延迟 0.5 秒保存，避免频繁写入
        saveDebounce?.cancel()
        saveDebounce = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let config = Config(
                apiKey: self.apiKey,
                aiBaseURL: self.aiBaseURL,
                aiModel: self.aiModel,
                voiceEnabled: self.voiceEnabled,
                petScale: self.petScale,
                selectedSkin: self.selectedSkin,
                petColorHex: self.petColorHex
            )
            self.writeConfig(config)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: saveDebounce!)
    }

    private func writeConfig(_ config: Config) {
        // 直接用 JSONSerialization 输出，不转义斜杠
        let dict: [String: Any] = [
            "aiBaseURL": config.aiBaseURL,
            "aiModel": config.aiModel,
            "apiKey": config.apiKey,
            "petColorHex": config.petColorHex,
            "petScale": config.petScale,
            "selectedSkin": config.selectedSkin,
            "voiceEnabled": config.voiceEnabled
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]) else { return }
        // 将 2 空格缩进转换为 4 空格，并去掉斜杠转义
        guard var jsonString = String(data: data, encoding: .utf8) else { return }
        jsonString = jsonString.replacingOccurrences(of: "\n  ", with: "\n    ")
        jsonString = jsonString.replacingOccurrences(of: "\\/", with: "/")
        guard let finalData = jsonString.data(using: .utf8) else { return }
        try? finalData.write(to: configURL)
    }

    // MARK: - Migration (可选：从 UserDefaults 迁移)

    func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard
        let migratedKey = "configMigratedToV2"

        guard !defaults.bool(forKey: migratedKey) else { return }

        // 读取旧的 UserDefaults 值
        if let key = defaults.string(forKey: "apiKey"), !key.isEmpty {
            apiKey = key
        }
        if let url = defaults.string(forKey: "aiBaseURL"), !url.isEmpty {
            aiBaseURL = url
        }
        if let model = defaults.string(forKey: "aiModel"), !model.isEmpty {
            aiModel = model
        }

        voiceEnabled = defaults.bool(forKey: "voiceEnabled")
        petScale = defaults.double(forKey: "petScale")
        if petScale == 0 { petScale = 4.0 }

        if let skin = defaults.string(forKey: "selectedSkin"), !skin.isEmpty {
            selectedSkin = skin
        }
        if let color = defaults.string(forKey: "petColorHex"), !color.isEmpty {
            petColorHex = color
        }

        // 标记已迁移
        defaults.set(true, forKey: migratedKey)

        // 立即保存
        saveDebounce?.cancel()
        let config = Config(
            apiKey: apiKey, aiBaseURL: aiBaseURL, aiModel: aiModel,
            voiceEnabled: voiceEnabled, petScale: petScale,
            selectedSkin: selectedSkin, petColorHex: petColorHex
        )
        writeConfig(config)
    }
}