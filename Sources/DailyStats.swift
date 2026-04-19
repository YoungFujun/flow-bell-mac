import Foundation

private struct LegacyDayRecord: Codable, Identifiable {
    var date: Date
    var focusMinutes: Int
    var sessions: Int

    var id: TimeInterval { date.timeIntervalSince1970 }
}

@MainActor
final class DailyStatsStore: ObservableObject {
    @Published private(set) var focusMinutesToday: Int = 0
    @Published private(set) var sessionsToday: Int = 0

    private let defaults = UserDefaults.standard
    private let focusKey = "stats.todayFocusMinutes"
    private let sessionsKey = "stats.todaySessions"
    private let dayKey = "stats.todayDate"
    private let legacyRecordsKey = "stats.weekRecords"
    private let calendar = Calendar.current
    private var lastSyncedDay: Date?

    init() {
        migrateLegacyWeekRecordsIfNeeded()
        syncToday()
    }

    func checkAndResetIfDayChanged() {
        let today = calendar.startOfDay(for: Date())
        if lastSyncedDay != today {
            syncToday()
        }
    }

    func recordCompletedSession(focusMinutes: Double) {
        checkAndResetIfDayChanged()
        focusMinutesToday += Int(focusMinutes.rounded())
        sessionsToday += 1
        save()
    }

    private func syncToday() {
        let today = calendar.startOfDay(for: Date())
        lastSyncedDay = today
        if let storedDate = defaults.object(forKey: dayKey) as? Date,
           calendar.isDate(storedDate, inSameDayAs: today) {
            focusMinutesToday = defaults.integer(forKey: focusKey)
            sessionsToday = defaults.integer(forKey: sessionsKey)
        } else {
            focusMinutesToday = 0
            sessionsToday = 0
            save(for: today)
        }
    }

    private func migrateLegacyWeekRecordsIfNeeded() {
        guard defaults.object(forKey: dayKey) == nil,
              let data = defaults.data(forKey: legacyRecordsKey),
              let decoded = try? JSONDecoder().decode([LegacyDayRecord].self, from: data) else {
            return
        }

        let today = calendar.startOfDay(for: Date())
        if let todayRecord = decoded.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            focusMinutesToday = todayRecord.focusMinutes
            sessionsToday = todayRecord.sessions
        }

        defaults.removeObject(forKey: legacyRecordsKey)
        save(for: today)
    }

    private func save(for day: Date = Calendar.current.startOfDay(for: Date())) {
        defaults.set(focusMinutesToday, forKey: focusKey)
        defaults.set(sessionsToday, forKey: sessionsKey)
        defaults.set(day, forKey: dayKey)
    }
}
