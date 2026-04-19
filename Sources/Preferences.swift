import Foundation
import SwiftUI

struct BlockedApp: Codable, Equatable, Hashable, Identifiable {
    let bundleIdentifier: String
    let displayName: String

    var id: String { bundleIdentifier }
}

struct SystemSound: Identifiable, Equatable {
    let name: String
    var id: String { name }

    var displayName: String { name }
}

enum LanguageChoice: String, Codable, CaseIterable, Identifiable {
    case chinese
    case english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chinese: L10n.chinese
        case .english: L10n.english
        }
    }

    var code: String {
        switch self {
        case .chinese: "zh-Hans"
        case .english: "en"
        }
    }
}

enum AccentColorChoice: String, Codable, CaseIterable, Identifiable {
    case systemBlue
    case sage
    case sierra
    case lavender
    case rose
    case titanium
    case starlight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .systemBlue: L10n.classicBlue
        case .sage:       L10n.sage
        case .sierra:     L10n.sierraBlue
        case .lavender:   L10n.lavender
        case .rose:       L10n.rose
        case .titanium:   L10n.titanium
        case .starlight:  L10n.starlight
        }
    }

    var color: Color {
        switch self {
        case .systemBlue: Color(red: 0.000, green: 0.478, blue: 1.000) // iOS System Blue #007AFF
        case .sage:       Color(red: 0.380, green: 0.573, blue: 0.455)
        case .sierra:     Color(red: 0.424, green: 0.620, blue: 0.784)
        case .lavender:   Color(red: 0.573, green: 0.490, blue: 0.710)
        case .rose:       Color(red: 0.784, green: 0.455, blue: 0.490)
        case .titanium:   Color(red: 0.490, green: 0.490, blue: 0.510)
        case .starlight:  Color(red: 0.686, green: 0.580, blue: 0.400)
        }
    }
}

enum MenuBarDisplayStyle: String, Codable, CaseIterable, Identifiable {
    case digital
    case ring

    var id: String { rawValue }

    var title: String {
        switch self {
        case .digital: L10n.digitalClock
        case .ring: L10n.progressRing
        }
    }
}

enum FocusPresetChoice: String, Codable, CaseIterable, Identifiable {
    case custom
    case flow
    case pomodoro
    case deepwork

    var id: String { rawValue }

    var title: String {
        switch self {
        case .custom: L10n.custom
        case .flow: "Flow 90/20"
        case .pomodoro: "Pomodoro 30/5"
        case .deepwork: "Focus 50/10"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var focusMinutes: Double = 90
    var breakMinutes: Double = 20
    var pingMinMinutes: Double = 3
    var pingMaxMinutes: Double = 5
    var microBreakSeconds: Double = 10
    var soundName: String = "Glass"
    var microBreakEndCueEnabled: Bool = true
    var autoStartNextSession: Bool = false
    var menuBarDisplayStyle: MenuBarDisplayStyle = .digital
    var accentColorChoice: AccentColorChoice = .sage
    var languageChoice: LanguageChoice = .chinese
    var blockedApps: [BlockedApp] = []
    var showTaskPrompt: Bool = true

    // Codable compatibility: provide default values for missing keys
    enum CodingKeys: String, CodingKey {
        case focusMinutes
        case breakMinutes
        case pingMinMinutes
        case pingMaxMinutes
        case microBreakSeconds
        case soundName
        case microBreakEndCueEnabled
        case autoStartNextSession
        case menuBarDisplayStyle
        case accentColorChoice
        case languageChoice
        case blockedApps
        case showTaskPrompt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        focusMinutes = try container.decodeIfPresent(Double.self, forKey: .focusMinutes) ?? 90
        breakMinutes = try container.decodeIfPresent(Double.self, forKey: .breakMinutes) ?? 20
        pingMinMinutes = try container.decodeIfPresent(Double.self, forKey: .pingMinMinutes) ?? 3
        pingMaxMinutes = try container.decodeIfPresent(Double.self, forKey: .pingMaxMinutes) ?? 5
        microBreakSeconds = try container.decodeIfPresent(Double.self, forKey: .microBreakSeconds) ?? 10
        soundName = try container.decodeIfPresent(String.self, forKey: .soundName) ?? "Glass"
        microBreakEndCueEnabled = try container.decodeIfPresent(Bool.self, forKey: .microBreakEndCueEnabled) ?? true
        autoStartNextSession = try container.decodeIfPresent(Bool.self, forKey: .autoStartNextSession) ?? false
        menuBarDisplayStyle = try container.decodeIfPresent(MenuBarDisplayStyle.self, forKey: .menuBarDisplayStyle) ?? .digital
        accentColorChoice = try container.decodeIfPresent(AccentColorChoice.self, forKey: .accentColorChoice) ?? .sage
        languageChoice = try container.decodeIfPresent(LanguageChoice.self, forKey: .languageChoice) ?? .chinese
        blockedApps = try container.decodeIfPresent([BlockedApp].self, forKey: .blockedApps) ?? []
        showTaskPrompt = try container.decodeIfPresent(Bool.self, forKey: .showTaskPrompt) ?? true
    }

    init() {
        // Default values already set above
    }

    static let defaultValue = AppSettings()

    var focusDuration: TimeInterval { focusMinutes * 60 }
    var breakDuration: TimeInterval { breakMinutes * 60 }
    var pingMinDuration: TimeInterval { pingMinMinutes * 60 }
    var pingMaxDuration: TimeInterval { max(pingMinMinutes, pingMaxMinutes) * 60 }
    var microBreakDuration: TimeInterval { microBreakSeconds }

    static let availableSystemSounds: [SystemSound] = {
        let soundsPath = "/System/Library/Sounds"
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: soundsPath) else {
            return [SystemSound(name: "Glass")]
        }
        let soundNames = files
            .filter { $0.hasSuffix(".aiff") }
            .map { $0.replacingOccurrences(of: ".aiff", with: "") }
            .sorted()
        return soundNames.map { SystemSound(name: $0) }
    }()
}

final class PreferencesStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            // 当语言切换时，触发 UI 刷新
            if oldValue.languageChoice != settings.languageChoice {
                L10n.configure(language: settings.languageChoice)
            }
            save()
        }
    }

    private let defaultsKey = "flow.random.bell.settings"
    private let defaults = UserDefaults.standard

    init() {
        let loadedSettings: AppSettings
        if let data = defaults.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            loadedSettings = decoded
        } else {
            loadedSettings = .defaultValue
        }
        settings = loadedSettings
        L10n.configure(language: loadedSettings.languageChoice)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }
        defaults.set(data, forKey: defaultsKey)
    }

}
