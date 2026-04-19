import AppKit
import SwiftUI

struct ContentView: View {
    private enum SettingsRoute {
        case main
        case blockedApps
        case weekStats
    }

    @EnvironmentObject private var preferences: PreferencesStore
    @EnvironmentObject private var engine: FocusEngine
    @EnvironmentObject private var installedApps: InstalledAppsStore
    @EnvironmentObject private var dailyStats: DailyStatsStore
    @State private var appSearchQuery = ""
    @State private var settingsRoute: SettingsRoute = .main

    @State private var durationExpanded = false
    @State private var soundExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            headerCard
            menuBarPickerRow
            Divider()
            sessionCard
            Divider()
            switch settingsRoute {
            case .main:
                settingsForm
            case .blockedApps:
                blockedAppsManager
            case .weekStats:
                weekStatsView
            }
            Divider()
            footerRow
        }
        .background(Color.white.opacity(0.72))
        .background(.ultraThinMaterial)
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(engine.phaseCaption)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Text(engine.timeLabel())
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            Spacer()
            headerRing
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var headerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 8)
            Circle()
                .trim(from: 0, to: max(engine.progressValue(), 0.015))
                .stroke(
                    AngularGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.4)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Image(systemName: engine.menuBarSymbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: 64, height: 64)
    }

    // 菜单栏模式选择，放在 header 和 session 之间
    private var menuBarPickerRow: some View {
        HStack {
            Text("菜单栏")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: menuBarStyleBinding) {
                ForEach(MenuBarDisplayStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Session card

    private var sessionCard: some View {
        VStack(spacing: 12) {
            controlRow
            statsRow
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.primary.opacity(0.04))
    }

    private var controlRow: some View {
        HStack(spacing: 10) {
            actionButton(label: engine.primaryButtonLabel, action: { engine.primaryAction() },
                         prominent: true, disabled: !engine.canPrimaryAction)
            actionButton(label: "暂停", action: { engine.pauseAction() },
                         prominent: false, disabled: !engine.canPause)
            actionButton(label: "重置", action: { engine.stop() },
                         prominent: false, disabled: !engine.canReset)
        }
    }

    private func actionButton(label: String, action: @escaping () -> Void, prominent: Bool, disabled: Bool) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    prominent
                        ? (disabled ? Color.accentColor.opacity(0.35) : Color.accentColor)
                        : Color.primary.opacity(disabled ? 0.04 : 0.08),
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .foregroundStyle(prominent ? .white : Color.primary.opacity(disabled ? 0.3 : 1))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statPill(title: "本轮提示", value: "\(engine.pingCount)")
            statPill(title: "完成轮次", value: "\(engine.completedFocusSessions)")
            statPill(title: "今日专注", value: todayFocusLabel)
            statPill(title: "今日番茄", value: "\(dailyStats.sessionsToday)")
        }
    }

    private var todayFocusLabel: String {
        let m = dailyStats.focusMinutesToday
        if m >= 60 {
            let h = m / 60
            let rem = m % 60
            return rem == 0 ? "\(h)h" : "\(h)h\(rem)m"
        }
        return "\(m)m"
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Settings form (collapsible)

    private var settingsForm: some View {
        VStack(spacing: 0) {
            collapsibleSection(title: "时长", icon: "timer", isExpanded: $durationExpanded) {
                formRow("预设") {
                    Picker("", selection: presetBinding) {
                        Text("自定义").tag("custom")
                        Text("Flow 90/20").tag("flow")
                        Text("Pomodoro 25/5").tag("pomodoro")
                        Text("Deep Work 52/17").tag("deepwork")
                    }
                    .frame(width: 170)
                }
                formDivider()
                formStepperRow("专注时长", value: focusBinding, range: 15...180, step: 5, suffix: "分钟")
                formDivider()
                formStepperRow("休息时长", value: breakBinding, range: 5...60, step: 5, suffix: "分钟")
                formDivider()
                formStepperRow("随机最短", value: pingMinBinding, range: 1...15, step: 0.5, suffix: "分钟")
                formDivider()
                formStepperRow("随机最长", value: pingMaxBinding, range: 1...20, step: 0.5, suffix: "分钟")
                formDivider()
                formStepperRow("微休息", value: microBreakBinding, range: 5...30, step: 1, suffix: "秒")
            }

            Divider()

            collapsibleSection(title: "声音与行为", icon: "bell", isExpanded: $soundExpanded) {
                formRow("提示音") {
                    Picker("", selection: soundBinding) {
                        Text("Glass").tag("Glass")
                        Text("Hero").tag("Hero")
                        Text("Submarine").tag("Submarine")
                        Text("Funk").tag("Funk")
                    }
                    .frame(width: 170)
                    .onChange(of: preferences.settings.soundName) { name in
                        NSSound(named: NSSound.Name(name))?.play()
                    }
                }
                formDivider()
                formToggleRow("微休息结束提示音", isOn: microBreakEndCueBinding)
                formDivider()
                formToggleRow("休息结束后自动开始下一轮", isOn: autoStartBinding)
            }

            Divider()

            Button(action: { settingsRoute = .blockedApps }) {
                HStack {
                    Image(systemName: "apps.iphone.badge.plus")
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Text("专注禁用 App")
                        .foregroundStyle(Color(NSColor.labelColor))
                    Spacer()
                    Text("\(preferences.settings.blockedApps.count) 个")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 20)

            Button(action: { settingsRoute = .weekStats }) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Text("本周统计")
                        .foregroundStyle(Color(NSColor.labelColor))
                    Spacer()
                    Text(weekSummaryLabel)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 13))
    }

    private func collapsibleSection<Content: View>(
        title: String,
        icon: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.wrappedValue.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(NSColor.labelColor))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                VStack(spacing: 0) {
                    content()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func formRow<C: View>(_ label: String, @ViewBuilder control: () -> C) -> some View {
        HStack {
            Text(label)
            Spacer()
            control()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
    }

    private func formStepperRow(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        suffix: String
    ) -> some View {
        HStack {
            Text(label)
            Spacer()
            HStack(spacing: 6) {
                TextField("", value: value, formatter: numberFormatter(step: step))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 52)
                    .multilineTextAlignment(.trailing)
                Text(suffix)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                Stepper("", value: value, in: range, step: step)
                    .labelsHidden()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
    }

    private func formToggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
    }

    private func formDivider() -> some View {
        Divider().padding(.leading, 20)
    }

    // MARK: - Blocked apps

    private var blockedAppsManager: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button { settingsRoute = .main } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderless)
                Text("专注禁用 App")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            TextField("搜索应用，例如 微信", text: $appSearchQuery)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)

            let suggestions = installedApps.search(appSearchQuery, excluding: preferences.settings.blockedApps)
            if !appSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions) { app in
                        Button {
                            preferences.settings.blockedApps.append(app)
                            preferences.settings.blockedApps.sort {
                                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
                            }
                            appSearchQuery = ""
                        } label: {
                            HStack {
                                Text(app.displayName)
                                Spacer()
                                Text(bundleSuffix(app.bundleIdentifier))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 20)
                    }
                }
                .background(Color.primary.opacity(0.03))
            }

            if preferences.settings.blockedApps.isEmpty {
                Text("未设置禁用列表，专注期间允许打开任何 App。")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(preferences.settings.blockedApps) { app in
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(app.displayName)
                                Text(app.bundleIdentifier)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("移除") {
                                preferences.settings.blockedApps.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.03))
                        Divider().padding(.leading, 20)
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack {
            Text("Flow Bell")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Button("退出 App") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func numberFormatter(step: Double) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = step < 1 ? 1 : 0
        f.maximumFractionDigits = step < 1 ? 1 : 0
        f.usesGroupingSeparator = false
        return f
    }

    private func bundleSuffix(_ bundleID: String) -> String {
        bundleID.split(separator: ".").last.map(String.init) ?? bundleID
    }

    // MARK: - Bindings

    private var menuBarStyleBinding: Binding<MenuBarDisplayStyle> {
        Binding(get: { preferences.settings.menuBarDisplayStyle },
                set: { preferences.settings.menuBarDisplayStyle = $0 })
    }
    private var focusBinding: Binding<Double> {
        Binding(get: { preferences.settings.focusMinutes },
                set: { preferences.settings.focusMinutes = min(max($0, 15), 180) })
    }
    private var breakBinding: Binding<Double> {
        Binding(get: { preferences.settings.breakMinutes },
                set: { preferences.settings.breakMinutes = min(max($0, 5), 60) })
    }
    private var pingMinBinding: Binding<Double> {
        Binding(get: { preferences.settings.pingMinMinutes },
                set: {
                    let v = min(max($0, 1), 15)
                    preferences.settings.pingMinMinutes = v
                    if preferences.settings.pingMaxMinutes < v { preferences.settings.pingMaxMinutes = v }
                })
    }
    private var pingMaxBinding: Binding<Double> {
        Binding(get: { preferences.settings.pingMaxMinutes },
                set: {
                    let v = min(max($0, 1), 20)
                    preferences.settings.pingMaxMinutes = v
                    if preferences.settings.pingMinMinutes > v { preferences.settings.pingMinMinutes = v }
                })
    }
    private var microBreakBinding: Binding<Double> {
        Binding(get: { preferences.settings.microBreakSeconds },
                set: { preferences.settings.microBreakSeconds = min(max($0, 5), 30) })
    }
    private var soundBinding: Binding<String> {
        Binding(get: { preferences.settings.soundName },
                set: { preferences.settings.soundName = $0 })
    }
    private var autoStartBinding: Binding<Bool> {
        Binding(get: { preferences.settings.autoStartNextSession },
                set: { preferences.settings.autoStartNextSession = $0 })
    }
    private var microBreakEndCueBinding: Binding<Bool> {
        Binding(get: { preferences.settings.microBreakEndCueEnabled },
                set: { preferences.settings.microBreakEndCueEnabled = $0 })
    }
    private var weekSummaryLabel: String {
        let m = dailyStats.weekTotalMinutes
        if m == 0 { return "暂无记录" }
        if m >= 60 {
            let h = m / 60
            let rem = m % 60
            return rem == 0 ? "本周 \(h)h" : "本周 \(h)h\(rem)m"
        }
        return "本周 \(m)m"
    }

    private var weekStatsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button { settingsRoute = .main } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderless)
                Text("本周统计")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            HStack(spacing: 10) {
                statPill(title: "本周专注", value: formatMinutes(dailyStats.weekTotalMinutes))
                statPill(title: "本周番茄", value: "\(dailyStats.weekTotalSessions)")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            weekBarChart
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
    }

    private var weekBarChart: some View {
        let days = last7Days()
        let maxMinutes = days.map(\.minutes).max() ?? 1
        let barMaxHeight: CGFloat = 80

        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(days, id: \.label) { day in
                let fraction = maxMinutes > 0 ? CGFloat(day.minutes) / CGFloat(maxMinutes) : 0
                let barHeight = max(fraction * barMaxHeight, day.minutes > 0 ? 4 : 0)
                let isToday = day.isToday

                VStack(spacing: 4) {
                    if day.minutes > 0 {
                        Text(formatMinutes(day.minutes))
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    } else {
                        Text(" ").font(.system(size: 8))
                    }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isToday ? Color.accentColor : Color.accentColor.opacity(0.35))
                        .frame(height: barHeight == 0 ? 2 : barHeight)
                        .opacity(barHeight == 0 ? 0.15 : 1)
                    Text(day.label)
                        .font(.system(size: 9))
                        .foregroundStyle(isToday ? Color.accentColor : Color.secondary)
                        .fontWeight(isToday ? .semibold : .regular)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: barMaxHeight + 40)
    }

    private struct DayBar {
        let label: String
        let minutes: Int
        let isToday: Bool
    }

    private func last7Days() -> [DayBar] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().map { offset -> DayBar in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let rec = dailyStats.weekRecords.first { cal.isDate($0.date, inSameDayAs: date) }
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            formatter.locale = Locale(identifier: "zh_CN")
            let label = formatter.string(from: date)
            return DayBar(label: label, minutes: rec?.focusMinutes ?? 0, isToday: offset == 0)
        }
    }

    private func formatMinutes(_ m: Int) -> String {
        guard m > 0 else { return "0m" }
        if m >= 60 {
            let h = m / 60; let r = m % 60
            return r == 0 ? "\(h)h" : "\(h)h\(r)m"
        }
        return "\(m)m"
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "今天" }
        if cal.isDateInYesterday(date) { return "昨天" }
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private var presetBinding: Binding<String> {
        Binding(
            get: {
                let s = preferences.settings
                if s.focusMinutes == 90, s.breakMinutes == 20 { return "flow" }
                if s.focusMinutes == 25, s.breakMinutes == 5  { return "pomodoro" }
                if s.focusMinutes == 52, s.breakMinutes == 17 { return "deepwork" }
                return "custom"
            },
            set: { preset in
                switch preset {
                case "flow":     preferences.settings.focusMinutes = 90; preferences.settings.breakMinutes = 20
                case "pomodoro": preferences.settings.focusMinutes = 25; preferences.settings.breakMinutes = 5
                case "deepwork": preferences.settings.focusMinutes = 52; preferences.settings.breakMinutes = 17
                default: break
                }
            }
        )
    }
}
