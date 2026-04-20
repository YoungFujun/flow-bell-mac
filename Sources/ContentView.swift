import AppKit
import SwiftUI

struct ContentView: View {
    private enum ScrollTarget: Hashable {
        case durationSection
        case soundSection
        case blockedAppsSection
    }

    private enum Palette {
        static let backgroundTint = Color(red: 1.0, green: 0.965, blue: 0.985).opacity(0.34)
        static let surfaceGlow = Color.white.opacity(0.22)
        static let sectionFill = Color.clear
        static let rowFill = Color.clear
        static let pillFill = Color.black.opacity(0.028)
        static let controlFill = Color.black.opacity(0.048)
        static let disabledControlFill = Color.black.opacity(0.024)
        static let menuFill = Color.black.opacity(0.03)
        static let divider = Color.black.opacity(0.035)
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
    private let panelHeight: CGFloat = 505

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
            softDivider
            footerRow
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(height: panelHeight, alignment: .top)
        .background {
            ZStack {
                Rectangle().fill(.regularMaterial)
                Rectangle().fill(Palette.backgroundTint)
                Rectangle().fill(Palette.surfaceGlow)
            }
        }
        .id(preferences.settings.languageChoice) // Force UI refresh when language changes
        .onChange(of: engine.shouldPromptForNextFocus) { shouldPrompt in
            guard shouldPrompt else { return }
            engine.clearShouldPromptForNextFocus()
            engine.showTaskPromptIfNeeded()
        }
    }

    private var homeContent: some View {
        VStack(spacing: 0) {
            headerCard
            menuBarPickerRow
            softDivider
            sessionCard
            softDivider
            presetRow
            softDivider
            durationSection
            softDivider
            settingsForm
        }
    }

    private var softDivider: some View {
        Rectangle()
            .fill(Palette.divider)
            .frame(height: 1)
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 4) {
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
            if let taskText = engine.currentTaskText, engine.phase == .focus {
                Text(taskText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
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
            Text(L10n.menuBar)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 0) {
                ForEach(MenuBarDisplayStyle.allCases) { style in
                    let selected = preferences.settings.menuBarDisplayStyle == style
                    Button {
                        preferences.settings.menuBarDisplayStyle = style
                    } label: {
                        Text(style.title)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .foregroundStyle(selected ? .white : Color.primary.opacity(0.72))
                            .background(selected ? accent : Color.clear, in: RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 150)
            .padding(2)
            .background(Palette.menuFill, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var presetRow: some View {
        HStack {
            Text(L10n.preset)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            presetMenu
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
        .background(Palette.sectionFill)
    }

    private var controlRow: some View {
        HStack(spacing: 10) {
            Button(action: handleStartAction) {
                Text(engine.primaryButtonLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        engine.canPrimaryAction ? accent : accent.opacity(0.35),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!engine.canPrimaryAction)
            actionButton(label: L10n.pause, action: { engine.pauseAction() },
                         prominent: false, disabled: !engine.canPause)
            actionButton(label: L10n.reset, action: { engine.stop() },
                         prominent: false, disabled: !engine.canReset)
        }
    }

    private func handleStartAction() {
        engine.showTaskPromptIfNeeded()
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
                            : (disabled ? Palette.disabledControlFill : Palette.controlFill),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                .foregroundStyle(prominent ? .white : Color.primary.opacity(disabled ? 0.3 : 1))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statPill(title: L10n.todaySessions, value: "\(dailyStats.sessionsToday)")
            statPill(title: L10n.todayFocus, value: todayFocusLabel)
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
        .background(Palette.pillFill, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Settings form (collapsible)

    private var durationSection: some View {
        collapsibleSection(
            title: L10n.durationSettings,
            icon: "timer",
            isExpanded: $durationExpanded,
            scrollSectionID: .durationSection,
            onToggle: handleSectionToggle
        ) {
            formStepperRow(L10n.focusDuration, value: focusBinding, range: 15...180, step: 5, suffix: L10n.minutes)
            formDivider()
            formStepperRow(L10n.restDuration, value: breakBinding, range: 5...60, step: 5, suffix: L10n.minutes)
            formDivider()
            formStepperRow(L10n.randomMin, value: pingMinBinding, range: 1...15, step: 1, suffix: L10n.minutes)
            formDivider()
            formStepperRow(L10n.randomMax, value: pingMaxBinding, range: 1...20, step: 1, suffix: L10n.minutes)
            formDivider()
            formStepperRow(L10n.microBreak, value: microBreakBinding, range: 5...30, step: 1, suffix: L10n.seconds)
        }
        .font(.system(size: 13))
    }

    private var settingsForm: some View {
        VStack(spacing: 0) {
            collapsibleSection(
                title: L10n.soundAndBehavior,
                icon: "bell",
                isExpanded: $soundExpanded,
                scrollSectionID: .soundSection,
                onToggle: handleSectionToggle
            ) {
                formRow(L10n.bellSound) {
                    soundMenu
                }
                formDivider()
                formRow(L10n.languageLabel) {
                    languageMenu
                }
                formDivider()
                formToggleRow(L10n.showTaskPrompt, isOn: showTaskPromptBinding)
                formDivider()
                formToggleRow(L10n.microBreakEndCue, isOn: microBreakEndCueBinding)
                formDivider()
                formToggleRow(L10n.autoStartNext, isOn: autoStartBinding)
                formDivider()
                formRow(L10n.accentColor) {
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

            softDivider

            collapsibleSection(
                title: L10n.blockedApps,
                icon: "apps.iphone.badge.plus",
                subtitle: preferences.settings.blockedApps.isEmpty ? L10n.notConfigured : L10n.blockedAppsCount(count: preferences.settings.blockedApps.count),
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
        .background(Palette.rowFill)
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
        .background(Palette.rowFill)
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
        .background(Palette.rowFill)
    }

    private func formDivider() -> some View {
        softDivider.padding(.leading, 20)
    }

    private var presetMenu: some View {
        Menu {
            ForEach(FocusPresetChoice.allCases) { preset in
                Button {
                    applyPreset(preset)
                } label: {
                    if inferredPreset == preset {
                        Label(preset.title, systemImage: "checkmark")
                    } else {
                        Text(preset.title)
                    }
                }
            }
        } label: {
            menuLabel(inferredPreset.title)
        }
        .buttonStyle(.plain)
        .frame(width: 170)
    }

    private var soundMenu: some View {
        Menu {
            ForEach(AppSettings.availableSystemSounds) { sound in
                Button {
                    preferences.settings.soundName = sound.name
                    let preview = NSSound(named: NSSound.Name(sound.name))
                    preview?.volume = 1.0
                    preview?.play()
                } label: {
                    if preferences.settings.soundName == sound.name {
                        Label(sound.displayName, systemImage: "checkmark")
                    } else {
                        Text(sound.displayName)
                    }
                }
            }
        } label: {
            menuLabel(preferences.settings.soundName)
        }
        .buttonStyle(.plain)
        .frame(width: 170)
    }

    private var languageMenu: some View {
        Menu {
            ForEach(LanguageChoice.allCases) { choice in
                Button {
                    preferences.settings.languageChoice = choice
                } label: {
                    if preferences.settings.languageChoice == choice {
                        Label(choice.title, systemImage: "checkmark")
                    } else {
                        Text(choice.title)
                    }
                }
            }
        } label: {
            menuLabel(preferences.settings.languageChoice.title)
        }
        .buttonStyle(.plain)
        .frame(width: 170)
    }

    private func menuLabel(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 6)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(accent)
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(Color.primary.opacity(0.8))
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(Palette.menuFill, in: RoundedRectangle(cornerRadius: 8))
    }

    private var blockedAppsContent: some View {
        VStack(spacing: 0) {
            TextField(L10n.searchApps, text: $appSearchQuery)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Palette.rowFill)

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
                        softDivider.padding(.leading, 20)
                    }
                }
                .background(Palette.rowFill)
            }

            if preferences.settings.blockedApps.isEmpty {
                Text(L10n.noBlockedList)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.rowFill)
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
                                    Text(L10n.allowed)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(accent)
                                    smallActionButton(L10n.cancel) {
                                        engine.revokeTemporaryAllowance(bundleID: app.bundleIdentifier)
                                    }
                                } else {
                                    smallActionButton(L10n.allow5Min, prominent: true) {
                                        engine.allowBlockedAppTemporarily(bundleID: app.bundleIdentifier)
                                    }
                                }

                                smallActionButton(L10n.remove) {
                                    engine.revokeTemporaryAllowance(bundleID: app.bundleIdentifier)
                                    preferences.settings.blockedApps.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Palette.rowFill)
                        softDivider.padding(.leading, 54)
                    }
                }
            }
        }
        .background(Palette.rowFill)
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack {
            Text("Flow Bell")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Button(L10n.quit) { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Palette.controlFill, in: RoundedRectangle(cornerRadius: 6))
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
                prominent ? accent : Palette.controlFill,
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
    private var languageBinding: Binding<LanguageChoice> {
        Binding(get: { preferences.settings.languageChoice },
                set: { preferences.settings.languageChoice = $0 })
    }
    private var inferredPreset: FocusPresetChoice {
        let s = preferences.settings
        if s.focusMinutes == 90, s.breakMinutes == 20 { return .flow }
        if s.focusMinutes == 30, s.breakMinutes == 5 { return .pomodoro }
        if s.focusMinutes == 50, s.breakMinutes == 10 { return .deepwork }
        return .custom
    }
    private var showTaskPromptBinding: Binding<Bool> {
        Binding(get: { preferences.settings.showTaskPrompt },
                set: { preferences.settings.showTaskPrompt = $0 })
    }
}
