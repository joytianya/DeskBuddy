// DeskBuddy/Config/ConfigStore.swift
import Foundation
import SwiftUI

/// 动画节奏配置（可序列化）
struct AnimationRhythmConfig: Codable {
    var playDuration: Double
    var pauseDuration: Double
    var frameInterval: Double
    var maxCycles: Int?   // nil = 无限循环
}

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
    /// 渲染模式：2d = 像素风，3d = SceneKit立体
    @Published var renderMode: String = "3d" {
        didSet { save() }
    }
    /// 动画节奏配置：key 为状态名（idle, happy 等）
    @Published var animationRhythms: [String: AnimationRhythmConfig] = defaultAnimationRhythms() {
        didSet { save() }
    }
    /// 窗口位置：保存上次关闭时的位置
    @Published var windowX: Double = 100.0 {
        didSet { save() }
    }
    @Published var windowY: Double = 100.0 {
        didSet { save() }
    }

    /// 默认动画节奏配置（8 个状态全覆盖）
    static func defaultAnimationRhythms() -> [String: AnimationRhythmConfig] {
        return [
            "idle": AnimationRhythmConfig(playDuration: 1.0, pauseDuration: 3.0, frameInterval: 0.15, maxCycles: 2),
            "happy": AnimationRhythmConfig(playDuration: 1.5, pauseDuration: 2.5, frameInterval: 0.15, maxCycles: nil),
            "sleepy": AnimationRhythmConfig(playDuration: 4.0, pauseDuration: 1.0, frameInterval: 0.30, maxCycles: nil),
            "anxious": AnimationRhythmConfig(playDuration: 0.8, pauseDuration: 0.5, frameInterval: 0.10, maxCycles: nil),
            "bored": AnimationRhythmConfig(playDuration: 1.0, pauseDuration: 4.0, frameInterval: 0.25, maxCycles: nil),
            "excited": AnimationRhythmConfig(playDuration: 1.0, pauseDuration: 2.0, frameInterval: 0.12, maxCycles: 2),
            "clingy": AnimationRhythmConfig(playDuration: 3.0, pauseDuration: 1.0, frameInterval: 0.18, maxCycles: nil),
            "lying": AnimationRhythmConfig(playDuration: 5.0, pauseDuration: 8.0, frameInterval: 0.50, maxCycles: nil)
        ]
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
        var renderMode: String = "3d"
        var animationRhythms: [String: AnimationRhythmConfig]?  // Optional 保持向后兼容
        var windowX: Double = 100.0
        var windowY: Double = 100.0
    }

    // MARK: - Load/Save

    private func load() {
        guard let data = try? Data(contentsOf: configURL) else {
            // 文件不存在，使用默认值
            return
        }

        // 使用JSONSerialization更灵活地加载（兼容旧配置）
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        apiKey = dict["apiKey"] as? String ?? ""
        aiBaseURL = dict["aiBaseURL"] as? String ?? "https://api.openai.com/v1"
        aiModel = dict["aiModel"] as? String ?? "gpt-4o-mini"
        voiceEnabled = dict["voiceEnabled"] as? Bool ?? false
        petScale = dict["petScale"] as? Double ?? 4.0
        selectedSkin = dict["selectedSkin"] as? String ?? "cat-sheet"
        petColorHex = dict["petColorHex"] as? String ?? "#FFFFFF"
        renderMode = dict["renderMode"] as? String ?? "3d"  // 新字段默认3d
        // 加载窗口位置（向后兼容：无字段时使用默认值 100.0）
        windowX = dict["windowX"] as? Double ?? 100.0
        windowY = dict["windowY"] as? Double ?? 100.0
        // 加载动画节奏配置（向后兼容：无字段时使用默认值）
        if let rhythmsDict = dict["animationRhythms"] as? [String: Any] {
            var loadedRhythms: [String: AnimationRhythmConfig] = [:]
            for (key, value) in rhythmsDict {
                if let rhythmDict = value as? [String: Any],
                   let playDuration = rhythmDict["playDuration"] as? Double,
                   let pauseDuration = rhythmDict["pauseDuration"] as? Double,
                   let frameInterval = rhythmDict["frameInterval"] as? Double {
                    let maxCycles = rhythmDict["maxCycles"] as? Int
                    loadedRhythms[key] = AnimationRhythmConfig(
                        playDuration: playDuration,
                        pauseDuration: pauseDuration,
                        frameInterval: frameInterval,
                        maxCycles: maxCycles
                    )
                }
            }
            if !loadedRhythms.isEmpty {
                animationRhythms = loadedRhythms
            }
        }
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
                petColorHex: self.petColorHex,
                renderMode: self.renderMode,
                animationRhythms: self.animationRhythms,
                windowX: self.windowX,
                windowY: self.windowY
            )
            self.writeConfig(config)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: saveDebounce!)
    }

    private func writeConfig(_ config: Config) {
        // 构建 animationRhythms dict
        var rhythmsDict: [String: Any] = [:]
        if let rhythms = config.animationRhythms {
            for (key, rhythm) in rhythms {
                rhythmsDict[key] = [
                    "playDuration": rhythm.playDuration,
                    "pauseDuration": rhythm.pauseDuration,
                    "frameInterval": rhythm.frameInterval,
                    "maxCycles": rhythm.maxCycles as Any
                ]
            }
        }
        // 直接用 JSONSerialization 输出，不转义斜杠
        let dict: [String: Any] = [
            "aiBaseURL": config.aiBaseURL,
            "aiModel": config.aiModel,
            "apiKey": config.apiKey,
            "animationRhythms": rhythmsDict,
            "petColorHex": config.petColorHex,
            "petScale": config.petScale,
            "renderMode": config.renderMode,
            "selectedSkin": config.selectedSkin,
            "voiceEnabled": config.voiceEnabled,
            "windowX": config.windowX,
            "windowY": config.windowY
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
            selectedSkin: selectedSkin, petColorHex: petColorHex,
            renderMode: renderMode, animationRhythms: animationRhythms,
            windowX: windowX, windowY: windowY
        )
        writeConfig(config)
    }
}