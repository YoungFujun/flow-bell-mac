import AppKit
import SwiftUI

struct ContentView: View {
    private enum ScrollTarget: Hashable {
        case durationSection
        case soundSection
        case blockedAppsSection
    }

    @EnvironmentObject private var preferences: PreferencesStore
    @EnvironmentObject private var engine: FocusEngine
    @EnvironmentObject private var installedApps: InstalledAppsStore
    @EnvironmentObject private var dailyStats: DailyStatsStore
    @State private var appSearchQuery = ""

    @State private var durationExpanded = false
    @State private var soundExpanded = false
    @State private var blockedAppsExpanded = false
    @State private var pendingScrollTarget: ScrollTarget?

    private var accent: Color { preferences.settings.accentColorChoice.color }
    private let panelHeight: CGFloat = 500

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    homeContent
                        .frame(maxWidth: .infinity, alignment: .top)
                }
                .onChange(of: pendingScrollTarget) { target in
                    guard let target else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(target, anchor: .center)
                        }
                        pendingScrollTarget = nil
                    }
                }
            }
            Divider()
            footerRow
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(height: panelHeight, alignment: .top)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var homeContent: some View {
        VStack(spacing: 0) {
            headerCard
            menuBarPickerRow
            Divider()
            sessionCard
            Divider()
            presetRow
            Divider()
            durationSection
            Divider()
            settingsForm
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(engine.phaseCaption)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Text(headerTimeLabel)
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
                        colors: [accent, accent.opacity(0.4)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Image(systemName: engine.menuBarSymbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(accent)
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
            .tint(accent)
            .frame(width: 150)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var presetRow: some View {
        HStack {
            Text("预设")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: presetBinding) {
                ForEach(FocusPresetChoice.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .tint(accent)
            .frame(width: 170)
            .onChange(of: preferences.settings.focusMinutes) { _ in applyPresetIfMatch() }
            .onChange(of: preferences.settings.breakMinutes) { _ in applyPresetIfMatch() }
        }
        .frame(height: 20)
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
    }

    private var presetBinding: Binding<FocusPresetChoice> {
        Binding(
            get: { inferredPreset },
            set: { applyPreset($0) }
        )
    }

    private func applyPresetIfMatch() {
        // 当时长设置改变时，自动更新预设显示（但不触发 applyPreset）
        // Binding 的 get 会自动根据当前时长推断预设
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
                        ? (disabled ? accent.opacity(0.35) : accent)
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
            statPill(title: "今日轮次", value: "\(dailyStats.sessionsToday)")
            statPill(title: "今日专注", value: todayFocusLabel)
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

    private var durationSection: some View {
        collapsibleSection(
            title: "时长设置",
            icon: "timer",
            isExpanded: $durationExpanded,
            scrollSectionID: .durationSection,
            onToggle: handleSectionToggle
        ) {
            formStepperRow("专注时长", value: focusBinding, range: 15...180, step: 5, suffix: "分钟")
            formDivider()
            formStepperRow("休息时长", value: breakBinding, range: 5...60, step: 5, suffix: "分钟")
            formDivider()
            formStepperRow("随机最短", value: pingMinBinding, range: 1...15, step: 1, suffix: "分钟")
            formDivider()
            formStepperRow("随机最长", value: pingMaxBinding, range: 1...20, step: 1, suffix: "分钟")
            formDivider()
            formStepperRow("微休息", value: microBreakBinding, range: 5...30, step: 1, suffix: "秒")
        }
        .font(.system(size: 13))
    }

    private var settingsForm: some View {
        VStack(spacing: 0) {
            collapsibleSection(
                title: "声音与行为",
                icon: "bell",
                isExpanded: $soundExpanded,
                scrollSectionID: .soundSection,
                onToggle: handleSectionToggle
            ) {
                formRow("提示音") {
                    Picker("", selection: soundBinding) {
                        Text("Glass").tag("Glass")
                        Text("Hero").tag("Hero")
                        Text("Submarine").tag("Submarine")
                        Text("Funk").tag("Funk")
                    }
                    .tint(accent)
                    .frame(width: 170)
                    .onChange(of: preferences.settings.soundName) { name in
                        let sound = NSSound(named: NSSound.Name(name))
                        sound?.volume = 1.0
                        sound?.play()
                    }
                }
                formDivider()
                formToggleRow("微休息结束提示音", isOn: microBreakEndCueBinding)
                formDivider()
                formToggleRow("休息结束后自动开始下一轮", isOn: autoStartBinding)
                formDivider()
                formRow("主题色") {
                    HStack(spacing: 8) {
                        ForEach(AccentColorChoice.allCases) { choice in
                            let selected = preferences.settings.accentColorChoice == choice
                            Circle()
                                .fill(choice.color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary.opacity(selected ? 0.7 : 0), lineWidth: 2)
                                        .padding(-3)
                                )
                                .onTapGesture {
                                    preferences.settings.accentColorChoice = choice
                                }
                        }
                    }
                }
            }

            Divider()

            collapsibleSection(
                title: "专注禁用 App",
                icon: "apps.iphone.badge.plus",
                subtitle: preferences.settings.blockedApps.isEmpty ? "未设置" : "\(preferences.settings.blockedApps.count) 个",
                isExpanded: $blockedAppsExpanded,
                scrollSectionID: .blockedAppsSection,
                onToggle: handleSectionToggle
            ) {
                blockedAppsContent
            }
        }
        .font(.system(size: 13))
    }

    private func collapsibleSection<Content: View>(
        title: String,
        icon: String,
        subtitle: String? = nil,
        isExpanded: Binding<Bool>,
        scrollSectionID: ScrollTarget? = nil,
        onToggle: ((Bool, ScrollTarget?) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: {
                let nextValue = !isExpanded.wrappedValue
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.wrappedValue = nextValue
                }
                onToggle?(nextValue, scrollSectionID)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(NSColor.labelColor))
                    Spacer()
                    if let subtitle, !isExpanded.wrappedValue {
                        Text(subtitle)
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                }
                .frame(height: 20)
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
        .id(scrollSectionID)
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
                TextField(
                    "",
                    value: value,
                    formatter: stepperNumberFormatter(step: step)
                )
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: step < 1 ? 48 : 44)
                .onSubmit {
                    value.wrappedValue = min(max(value.wrappedValue, range.lowerBound), range.upperBound)
                }
                Text(suffix.count == 1 ? " \(suffix)" : suffix)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, alignment: .leading)
                Stepper("", value: value, in: range, step: step)
                    .labelsHidden()
                    .tint(accent)
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
                .tint(accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
    }

    private func formDivider() -> some View {
        Divider().padding(.leading, 20)
    }

    private var blockedAppsContent: some View {
        VStack(spacing: 0) {
            TextField("搜索应用，例如 微信", text: $appSearchQuery)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.03))

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
                            HStack(spacing: 10) {
                                if let icon = appIcon(for: app.bundleIdentifier) {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                }
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
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.03))
            } else {
                VStack(spacing: 0) {
                    ForEach(preferences.settings.blockedApps) { app in
                        HStack(spacing: 10) {
                            if let icon = appIcon(for: app.bundleIdentifier) {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 28, height: 28)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(app.displayName)
                                Text(app.bundleIdentifier)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 12) {
                                if engine.temporarilyAllowedBundleIDs.contains(app.bundleIdentifier) {
                                    Text("已放行")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(accent)
                                    smallActionButton("取消") {
                                        engine.revokeTemporaryAllowance(bundleID: app.bundleIdentifier)
                                    }
                                } else {
                                    smallActionButton("放行 5 分", prominent: true) {
                                        engine.allowBlockedAppTemporarily(bundleID: app.bundleIdentifier)
                                    }
                                }

                                smallActionButton("移除") {
                                    engine.revokeTemporaryAllowance(bundleID: app.bundleIdentifier)
                                    preferences.settings.blockedApps.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.03))
                        Divider().padding(.leading, 54)
                    }
                }
            }
        }
        .background(Color.primary.opacity(0.03))
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack {
            Text("Flow Bell")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Button("退出") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func handleSectionToggle(_ isExpanded: Bool, _ scrollTarget: ScrollTarget?) {
        guard isExpanded else { return }
        pendingScrollTarget = scrollTarget
    }

    private var headerTimeLabel: String {
        if engine.phase == .idle {
            return shortTime(preferences.settings.focusDuration)
        }
        return engine.timeLabel()
    }

    private func shortTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func stepperNumberFormatter(step: Double) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.allowsFloats = true
        let digits = step < 1 ? 1 : 0
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        return formatter
    }

    private func applyPreset(_ preset: FocusPresetChoice) {
        switch preset {
        case .flow:
            preferences.settings.focusMinutes = 90
            preferences.settings.breakMinutes = 20
        case .pomodoro:
            preferences.settings.focusMinutes = 30
            preferences.settings.breakMinutes = 5
        case .deepwork:
            preferences.settings.focusMinutes = 50
            preferences.settings.breakMinutes = 10
        case .custom:
            break
        }
    }

    private func smallActionButton(_ title: String, prominent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(prominent ? .white : Color.primary.opacity(0.8))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                prominent ? accent : Color.primary.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
    }

    private func bundleSuffix(_ bundleID: String) -> String {
        bundleID.split(separator: ".").last.map(String.init) ?? bundleID
    }

    private func appIcon(for bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    // MARK: - Bindings

    private var menuBarStyleBinding: Binding<MenuBarDisplayStyle> {
        Binding(get: { preferences.settings.menuBarDisplayStyle },
                set: { preferences.settings.menuBarDisplayStyle = $0 })
    }
    private var focusBinding: Binding<Double> {
        Binding(get: { preferences.settings.focusMinutes },
                set: {
                    preferences.settings.focusMinutes = min(max($0, 15), 180)
                })
    }
    private var breakBinding: Binding<Double> {
        Binding(get: { preferences.settings.breakMinutes },
                set: {
                    preferences.settings.breakMinutes = min(max($0, 5), 60)
                })
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
                set: {
                    preferences.settings.microBreakSeconds = min(max($0, 5), 30)
                })
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
    private var inferredPreset: FocusPresetChoice {
        let s = preferences.settings
        if s.focusMinutes == 90, s.breakMinutes == 20 { return .flow }
        if s.focusMinutes == 30, s.breakMinutes == 5 { return .pomodoro }
        if s.focusMinutes == 50, s.breakMinutes == 10 { return .deepwork }
        return .custom
    }
}
