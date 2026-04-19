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
        case .blue:   "天蓝"
        case .green:  "薄荷"
        case .brown:  "珊瑚"
        case .gray:   "薰衣草"
        case .purple: "石板蓝"
        }
    }

    var color: Color {
        switch self {
        case .blue:   Color(red: 0.129, green: 0.588, blue: 0.953) // 天蓝 #2196F3
        case .green:  Color(red: 0.000, green: 0.749, blue: 0.647) // 薄荷绿 #00BFA5
        case .brown:  Color(red: 1.000, green: 0.420, blue: 0.420) // 珊瑚橙 #FF6B6B
        case .gray:   Color(red: 0.612, green: 0.639, blue: 0.953) // 薰衣草紫 #9C88FF
        case .purple: Color(red: 0.369, green: 0.416, blue: 0.824) // 石板蓝 #5C6BC0
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
