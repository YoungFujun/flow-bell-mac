import Foundation

struct DayRecord: Codable, Identifiable {
    var date: Date
    var focusMinutes: Int
    var sessions: Int

    var id: TimeInterval { date.timeIntervalSince1970 }
}

final class DailyStatsStore: ObservableObject {
    @Published private(set) var focusMinutesToday: Int = 0
    @Published private(set) var sessionsToday: Int = 0
    @Published private(set) var weekRecords: [DayRecord] = []

    private let defaults = UserDefaults.standard
    private let recordsKey = "stats.weekRecords"
    private let calendar = Calendar.current

    init() {
        load()
        pruneOldRecords()
        syncToday()
    }

    func recordCompletedSession(focusMinutes: Double) {
        let today = calendar.startOfDay(for: Date())
        if let idx = weekRecords.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            weekRecords[idx].focusMinutes += Int(focusMinutes.rounded())
            weekRecords[idx].sessions += 1
        } else {
            weekRecords.append(DayRecord(date: today, focusMinutes: Int(focusMinutes.rounded()), sessions: 1))
        }
        save()
        syncToday()
    }

    var weekTotalMinutes: Int { weekRecords.reduce(0) { $0 + $1.focusMinutes } }
    var weekTotalSessions: Int { weekRecords.reduce(0) { $0 + $1.sessions } }

    var sortedWeekRecords: [DayRecord] {
        weekRecords.sorted { $0.date > $1.date }
    }

    private func syncToday() {
        let today = calendar.startOfDay(for: Date())
        if let rec = weekRecords.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            focusMinutesToday = rec.focusMinutes
            sessionsToday = rec.sessions
        } else {
            focusMinutesToday = 0
            sessionsToday = 0
        }
    }

    private func pruneOldRecords() {
        let cutoff = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))!
        weekRecords = weekRecords.filter { $0.date >= cutoff }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: recordsKey),
              let decoded = try? JSONDecoder().decode([DayRecord].self, from: data) else {
            weekRecords = []
            return
        }
        weekRecords = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(weekRecords) else { return }
        defaults.set(data, forKey: recordsKey)
    }
}
