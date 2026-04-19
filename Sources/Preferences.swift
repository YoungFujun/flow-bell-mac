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
    case orange
    case pink
    case purple
    case teal
    case indigo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blue:   "蓝"
        case .green:  "绿"
        case .orange: "橙"
        case .pink:   "粉"
        case .purple: "紫"
        case .teal:   "青"
        case .indigo: "靛"
        }
    }

    var color: Color {
        switch self {
        case .blue:   Color(red: 0.000, green: 0.478, blue: 1.000) // #007AFF
        case .green:  Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759
        case .orange: Color(red: 1.000, green: 0.584, blue: 0.000) // #FF9500
        case .pink:   Color(red: 1.000, green: 0.176, blue: 0.333) // #FF2D55
        case .purple: Color(red: 0.686, green: 0.322, blue: 0.871) // #AF52DE
        case .teal:   Color(red: 0.353, green: 0.784, blue: 0.980) // #5AC8FA
        case .indigo: Color(red: 0.345, green: 0.337, blue: 0.839) // #5856D6
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
