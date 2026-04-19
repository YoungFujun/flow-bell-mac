import Foundation
import SwiftUI

struct BlockedApp: Codable, Equatable, Hashable, Identifiable {
    let bundleIdentifier: String
    let displayName: String

    var id: String { bundleIdentifier }
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
        case .systemBlue: "经典蓝"
        case .sage:       "鼠尾草"
        case .sierra:     "山脉蓝"
        case .lavender:   "薰衣草"
        case .rose:       "玫瑰"
        case .titanium:   "钛金"
        case .starlight:  "星光"
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
        case .digital: "数字时钟"
        case .ring: "圆环盈缺"
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
    var blockedApps: [BlockedApp] = []

    static let defaultValue = AppSettings()

    var focusDuration: TimeInterval { focusMinutes * 60 }
    var breakDuration: TimeInterval { breakMinutes * 60 }
    var pingMinDuration: TimeInterval { pingMinMinutes * 60 }
    var pingMaxDuration: TimeInterval { max(pingMinMinutes, pingMaxMinutes) * 60 }
    var microBreakDuration: TimeInterval { microBreakSeconds }
}

final class PreferencesStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            save()
        }
    }

    private let defaultsKey = "flow.random.bell.settings"
    private let defaults = UserDefaults.standard

    init() {
        if let data = defaults.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .defaultValue
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }
        defaults.set(data, forKey: defaultsKey)
    }
}
