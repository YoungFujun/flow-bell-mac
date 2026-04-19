import Foundation
import SwiftUI

struct BlockedApp: Codable, Equatable, Hashable, Identifiable {
    let bundleIdentifier: String
    let displayName: String

    var id: String { bundleIdentifier }
}

enum AccentColorChoice: String, Codable, CaseIterable, Identifiable {
    case blue
    case green
    case brown
    case gray
    case purple

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blue:   "蓝"
        case .green:  "绿"
        case .brown:  "棕"
        case .gray:   "灰"
        case .purple: "紫"
        }
    }

    var color: Color {
        switch self {
        case .blue:   Color(red: 0.290, green: 0.565, blue: 0.851)
        case .green:  Color(red: 0.290, green: 0.486, blue: 0.349)
        case .brown:  Color(red: 0.545, green: 0.451, blue: 0.333)
        case .gray:   Color(red: 0.420, green: 0.420, blue: 0.420)
        case .purple: Color(red: 0.482, green: 0.408, blue: 0.710)
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
    var accentColorChoice: AccentColorChoice = .blue
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
