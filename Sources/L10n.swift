import Foundation

struct L10n {
    private static var currentLanguage: LanguageChoice = .chinese

    static func configure(language: LanguageChoice) {
        Self.currentLanguage = language
    }

    // FocusEngine states
    static var ready: String { tr("Ready", "准备") }
    static var focus: String { tr("Focus", "专注") }
    static var rest: String { tr("Rest", "休息") }
    static var readyUpper: String { tr("READY", "准备") }
    static var focusUpper: String { tr("FOCUS", "专注中") }
    static var focusPaused: String { tr("FOCUS PAUSED", "专注暂停") }
    static var breakUpper: String { tr("BREAK", "休息中") }
    static var breakPaused: String { tr("BREAK PAUSED", "休息暂停") }

    // FocusEngine helper lines
    static func helperIdle() -> String { tr("Start a focus session. Random bell cues will ring at irregular intervals.", "开始一轮专注。专注中会在随机区间内响起系统提示音。") }
    static func helperFocus(seconds: Int) -> String {
        tr("Keep your flow uninterrupted. Pause briefly for %d seconds when the bell rings.", "保持工作流不断开，只在提示音响起时短暂停 %d 秒。").replacingOccurrences(of: "%d", with: String(seconds))
    }
    static var helperRest: String { tr("Now entering real rest time. Full-screen countdown has taken over your screen.", "现在进入真正的休息时间，全屏倒计时已接管屏幕。") }

    // Buttons
    static var inProgress: String { tr("In Progress", "进行中") }
    static var resume: String { tr("Resume", "继续") }
    static var pause: String { tr("Pause", "暂停") }
    static var reset: String { tr("Reset", "重置") }
    static var start: String { tr("Start", "开始") }

    // Notifications
    static func restStarted(minutes: Int) -> String {
        tr("%d-minute recovery rest has started.", "%d 分钟恢复休息开始。").replacingOccurrences(of: "%d", with: String(minutes))
    }
    static var randomBell: String { tr("Random Bell", "随机提示音") }
    static func closeYourEyes(seconds: Int) -> String {
        tr("Close your eyes and rest for %d seconds.", "闭眼休息 %d 秒。").replacingOccurrences(of: "%d", with: String(seconds))
    }
    static var backToFocus: String { tr("Back to focus.", "回到专注。") }
    static var restEnded: String { tr("Rest ended. You can start a new focus session.", "休息结束，可以开始下一轮专注。") }

    // Rest overlay
    static var restAWhile: String { tr("Rest a while", "休息一下") }
    static var stepAwayFromScreen: String { tr("Step away from screen, relax your eyes", "离开屏幕、放松眼睛") }
    static var minimize: String { tr("Minimize", "最小化") }
    static var endRest: String { tr("End Rest", "提前结束") }
    static var nextFocus: String { tr("Next Focus", "下一轮专注") }
    static func restTime(time: String) -> String {
        tr("Rest %s", "休息 %s").replacingOccurrences(of: "%s", with: time)
    }

    // Micro break
    static func closeEyesRest(seconds: Int) -> String {
        tr("Close eyes and rest %d seconds", "闭眼休息 %d 秒").replacingOccurrences(of: "%d", with: String(seconds))
    }
    static func secondsLabel(seconds: Int) -> String {
        tr("%ds", "%d秒").replacingOccurrences(of: "%d", with: String(seconds))
    }

    // Block notice
    static var allowedFor5Min: String { tr("Allowed for 5 min", "已放行") }
    static func blockedAppName(name: String) -> String {
        tr("Blocked: %s", "已拦截 %s").replacingOccurrences(of: "%s", with: name)
    }
    static var cancel: String { tr("Cancel", "取消") }
    static var allow5Min: String { tr("Allow 5 min", "放行 5 分") }
    static var remove: String { tr("Remove", "移除") }
    static var thisApp: String { tr("this app", "该应用") }

    // ContentView
    static var menuBar: String { tr("Menu Bar", "菜单栏") }
    static var digitalClock: String { tr("Clock", "数字时钟") }
    static var progressRing: String { tr("Ring", "圆环盈缺") }
    static var preset: String { tr("Preset", "预设") }
    static var custom: String { tr("Custom", "手动设置") }
    static var flow90_20: String { "Flow 90/20" }
    static var pomodoro30_5: String { "Pomodoro 30/5" }
    static var focus50_10: String { "Focus 50/10" }
    static var todaySessions: String { tr("Today Sessions", "今日轮次") }
    static var todayFocus: String { tr("Today Focus", "今日专注") }

    // Settings sections
    static var durationSettings: String { tr("Duration Settings", "时长设置") }
    static var focusDuration: String { tr("Focus Duration", "专注时长") }
    static var restDuration: String { tr("Rest Duration", "休息时长") }
    static var randomMin: String { tr("Random Min", "随机最短") }
    static var randomMax: String { tr("Random Max", "随机最长") }
    static var microBreak: String { tr("Micro Break", "微休息") }
    static var minutes: String { tr("min", "分钟") }
    static var seconds: String { tr("seconds", "秒") }
    static var soundAndBehavior: String { tr("Sound & Behavior", "声音与行为") }
    static var bellSound: String { tr("Bell Sound", "提示音") }
    static var languageLabel: String { tr("Language", "语言") }
    static var microBreakEndCue: String { tr("Micro break end cue", "微休息结束提示音") }
    static var autoStartNext: String { tr("Auto-start next focus after rest", "休息结束后自动开始下一轮") }
    static var accentColor: String { tr("Accent Color", "主题色") }
    static var blockedApps: String { tr("Blocked Apps", "专注禁用 App") }
    static func blockedAppsCount(count: Int) -> String {
        tr("%d apps", "%d 个").replacingOccurrences(of: "%d", with: String(count))
    }
    static var notConfigured: String { tr("Not configured", "未设置") }
    static var searchApps: String { tr("Search apps, e.g. WeChat", "搜索应用，例如 微信") }
    static var noBlockedList: String { tr("No blocked list set. Any app can be opened during focus.", "未设置禁用列表，专注期间允许打开任何 App。") }
    static var allowed: String { tr("Allowed", "已放行") }
    static var quit: String { tr("Quit", "退出") }

    // Colors
    static var classicBlue: String { tr("Classic Blue", "经典蓝") }
    static var sage: String { tr("Sage", "鼠尾草") }
    static var sierraBlue: String { tr("Sierra Blue", "山脉蓝") }
    static var lavender: String { tr("Lavender", "薰衣草") }
    static var rose: String { tr("Rose", "玫瑰") }
    static var titanium: String { tr("Titanium", "钛金") }
    static var starlight: String { tr("Starlight", "星光") }

    // Micro break state
    static var microBreakInProgress: String { tr("Micro break in progress", "微休息进行中") }
    static var randomBellPaused: String { tr("Random bell paused", "随机提示已暂停") }
    static var noNewBellScheduled: String { tr("No new random bell scheduled for this session", "本轮后段不再安排新的随机提示") }
    static func randomBellActive(range: String) -> String {
        tr("Random bell active: next cue within %s", "随机提示进行中：下一次将在 %s 内出现").replacingOccurrences(of: "%s", with: range)
    }
    static func aroundTime(time: String) -> String {
        tr("around %s", "%s 左右").replacingOccurrences(of: "%s", with: time)
    }
    static func timeRange(min: String, max: String) -> String {
        let template = tr("%s to %s", "%s 到 %s")
        return template.replacingOccurrences(of: "%s", with: min + "|" + max)
            .replacingOccurrences(of: "%s|%s", with: max)
            .replacingOccurrences(of: min + "|", with: min)
    }
    static func minutesInt(minutes: Int) -> String {
        tr("%d minutes", "%d 分钟").replacingOccurrences(of: "%d", with: String(minutes))
    }
    static func minutesFloat(minutes: Double) -> String {
        tr("%.1f minutes", "%.1f 分钟").replacingOccurrences(of: "%.1f", with: String(format: "%.1f", minutes))
    }

    // Language choice titles
    static var chinese: String { "中文" }
    static var english: String { "English" }

    private static func tr(_ en: String, _ zh: String) -> String {
        switch currentLanguage {
        case .chinese: return zh
        case .english: return en
        }
    }
}