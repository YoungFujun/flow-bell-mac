import AppKit
import AVFAudio
import Foundation
import UserNotifications

@MainActor
final class FocusEngine: ObservableObject {
    enum Phase: String {
        case idle
        case focus
        case rest

        var title: String {
            switch self {
            case .idle: "Ready"
            case .focus: "Focus"
            case .rest: "Rest"
            }
        }
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var isRunning = false
    @Published private(set) var secondsRemaining: TimeInterval = 0
    @Published private(set) var activePromptText: String?
    @Published private(set) var promptEndsAt: Date?
    @Published private(set) var completedFocusSessions = 0
    @Published private(set) var pingCount = 0
    @Published private(set) var temporarilyAllowedBundleIDs: Set<String> = []

    var dailyStats: DailyStatsStore?

    private var settings = AppSettings.defaultValue
    private var timer: Timer?
    private var phaseEndDate: Date?
    private var nextPingDate: Date?
    private var pausedPhaseRemaining: TimeInterval?
    private var pausedPingRemaining: TimeInterval?
    private var isMicroBreakPromptActive = false
    private var hasConfigured = false
    private var workspaceObservers: [NSObjectProtocol] = []
    private let notificationCenter = UNUserNotificationCenter.current()
    private let restOverlayController = RestOverlayController()
    private let blockNoticeController = BlockNoticeController()
    private let microBreakNoticeController = MicroBreakNoticeController()
    private var temporarilyAllowedUntil: [String: Date] = [:]
    private var blockedNoticeLastShownAt: [String: Date] = [:]
    private let temporaryAllowDuration: TimeInterval = 5 * 60
    private let blockedNoticeCooldown: TimeInterval = 4

    init() {
        requestNotificationPermission()
    }

    var phaseTitle: String { phase.title }

    var phaseCaption: String {
        switch (phase, isRunning) {
        case (.idle, _):
            return L10n.readyUpper
        case (.focus, true):
            return L10n.focusUpper
        case (.focus, false):
            return L10n.focusPaused
        case (.rest, true):
            return L10n.breakUpper
        case (.rest, false):
            return L10n.breakPaused
        }
    }

    var helperLine: String {
        switch phase {
        case .idle:
            return L10n.helperIdle()
        case .focus:
            return L10n.helperFocus(seconds: Int(settings.microBreakSeconds))
        case .rest:
            return L10n.helperRest
        }
    }

    var primaryButtonLabel: String {
        switch (phase, isRunning) {
        case (.idle, _):
            return L10n.start
        case (_, true):
            return L10n.inProgress
        case (_, false):
            return L10n.resume
        }
    }

    var canPrimaryAction: Bool {
        phase == .idle || !isRunning
    }

    var canPause: Bool {
        phase != .idle && isRunning
    }

    var canReset: Bool {
        phase != .idle || secondsRemaining > 0 || pingCount > 0 || activePromptText != nil
    }

    var menuBarTitle: String {
        if isMicroBreakPromptActive {
            return microBreakCountdownTitle
        }
        switch phase {
        case .idle:
            return "Flow Bell"
        case .focus, .rest:
            return shortTime(secondsRemaining)
        }
    }

    var isShowingMicroBreakCountdown: Bool {
        isMicroBreakPromptActive
    }

    var menuBarSymbol: String {
        switch phase {
        case .idle: "bell.badge"
        case .focus: "circle.dotted"
        case .rest: "moon.zzz"
        }
    }

    func configure(preferences: PreferencesStore) {
        settings = preferences.settings
        if timer == nil {
            startTicker()
        }
        if workspaceObservers.isEmpty {
            startApplicationObservers()
        }
        if !hasConfigured {
            hasConfigured = true
        }
    }

    func apply(settings: AppSettings) {
        self.settings = settings
        if self.settings.pingMaxMinutes < self.settings.pingMinMinutes {
            self.settings.pingMaxMinutes = self.settings.pingMinMinutes
        }
    }

    func primaryAction() {
        switch (phase, isRunning) {
        case (.idle, _):
            startFocusSession()
        case (_, true):
            break
        case (_, false):
            resume()
        }
    }

    func pauseAction() {
        pause()
    }

    func stop() {
        reset()
    }

    func allowBlockedAppTemporarily(bundleID: String) {
        let until = Date().addingTimeInterval(temporaryAllowDuration)
        temporarilyAllowedUntil[bundleID] = until
        temporarilyAllowedBundleIDs.insert(bundleID)
        blockedNoticeLastShownAt.removeValue(forKey: bundleID)
        blockNoticeController.close()
    }

    func revokeTemporaryAllowance(bundleID: String) {
        temporarilyAllowedUntil.removeValue(forKey: bundleID)
        temporarilyAllowedBundleIDs.remove(bundleID)
    }

    private func startFocusSession() {
        clearTemporaryAllowances()
        phase = .focus
        isRunning = true
        activePromptText = nil
        promptEndsAt = nil
        isMicroBreakPromptActive = false
        phaseEndDate = Date().addingTimeInterval(settings.focusDuration)
        secondsRemaining = settings.focusDuration
        scheduleNextPing(from: Date())
    }

    private func startRestSession() {
        phase = .rest
        isRunning = true
        activePromptText = nil
        promptEndsAt = nil
        isMicroBreakPromptActive = false
        nextPingDate = nil
        phaseEndDate = Date().addingTimeInterval(settings.breakDuration)
        secondsRemaining = settings.breakDuration
        notify(title: L10n.rest, body: L10n.restStarted(minutes: Int(settings.breakMinutes)))
        play(named: "Hero", volumeGain: 2.0)
        restOverlayController.show(
            secondsRemaining: secondsRemaining,
            accentColor: settings.accentColorChoice.color,
            onSkip: { [weak self] in
                Task { @MainActor in
                    self?.finishRestToIdle()
                }
            },
            onNextFocus: { [weak self] in
                Task { @MainActor in
                    self?.finishRestAndStartNextFocus()
                }
            }
        )
    }

    private func finishRestToIdle() {
        restOverlayController.close()
        phase = .idle
        isRunning = false
        phaseEndDate = nil
        nextPingDate = nil
        secondsRemaining = 0
        activePromptText = L10n.restEnded
        promptEndsAt = Date().addingTimeInterval(8)
        isMicroBreakPromptActive = false
        notify(title: L10n.ready, body: L10n.restEnded)
        play(named: "Glass", volumeGain: 2.0)
    }

    private func finishRestAndStartNextFocus() {
        restOverlayController.close()
        startFocusSession()
    }

    private func finishRestSession() {
        if settings.autoStartNextSession {
            restOverlayController.close()
            startFocusSession()
        } else {
            restOverlayController.close()
            phase = .idle
            isRunning = false
            phaseEndDate = nil
            nextPingDate = nil
            secondsRemaining = 0
            activePromptText = L10n.restEnded
            promptEndsAt = Date().addingTimeInterval(8)
            isMicroBreakPromptActive = false
            notify(title: L10n.ready, body: L10n.restEnded)
            play(named: "Glass", volumeGain: 2.0)
        }
    }

    private func pause() {
        guard isRunning else { return }
        isRunning = false
        if let phaseEndDate {
            pausedPhaseRemaining = max(0, phaseEndDate.timeIntervalSinceNow)
        }
        if let nextPingDate {
            pausedPingRemaining = max(0, nextPingDate.timeIntervalSinceNow)
        }
    }

    private func resume() {
        guard !isRunning, phase != .idle else { return }
        isRunning = true
        if let pausedPhaseRemaining {
            phaseEndDate = Date().addingTimeInterval(pausedPhaseRemaining)
        }
        if phase == .focus {
            if let pausedPingRemaining {
                // ensure at least 30s buffer after resume
                nextPingDate = Date().addingTimeInterval(max(pausedPingRemaining, 30))
            }
        }
        self.pausedPhaseRemaining = nil
        self.pausedPingRemaining = nil
    }

    private func reset() {
        restOverlayController.close()
        microBreakNoticeController.close()
        clearTemporaryAllowances()
        phase = .idle
        isRunning = false
        secondsRemaining = 0
        phaseEndDate = nil
        nextPingDate = nil
        pausedPhaseRemaining = nil
        pausedPingRemaining = nil
        activePromptText = nil
        promptEndsAt = nil
        isMicroBreakPromptActive = false
        pingCount = 0
    }

    private func clearTemporaryAllowances() {
        temporarilyAllowedUntil.removeAll()
        temporarilyAllowedBundleIDs.removeAll()
        blockedNoticeLastShownAt.removeAll()
        blockNoticeController.close()
    }

    private func startTicker() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func tick() {
        let now = Date()

        // Check if day has changed, reset daily stats if needed
        dailyStats?.checkAndResetIfDayChanged()

        pruneTemporaryAllowances(at: now)

        if isMicroBreakPromptActive, let promptEndsAt {
            let remaining = max(0, promptEndsAt.timeIntervalSince(now))
            microBreakNoticeController.update(secondsRemaining: remaining)
        }

        if let promptEndsAt, now >= promptEndsAt {
            handlePromptEnd(at: now)
        }

        guard isRunning, let phaseEndDate else {
            return
        }

        secondsRemaining = max(0, phaseEndDate.timeIntervalSince(now))

        switch phase {
        case .focus:
            enforceBlockedFrontmostAppIfNeeded()
            if let nextPingDate, now >= nextPingDate, !isMicroBreakPromptActive {
                triggerPing()
                scheduleNextPing(from: now)
            }
            if now >= phaseEndDate {
                completedFocusSessions += 1
                dailyStats?.recordCompletedSession(focusMinutes: settings.focusMinutes)
                startRestSession()
            }
        case .rest:
            restOverlayController.update(secondsRemaining: secondsRemaining)
            if now >= phaseEndDate {
                finishRestSession()
            }
        case .idle:
            break
        }
    }

    private func triggerPing() {
        pingCount += 1
        activePromptText = L10n.closeYourEyes(seconds: Int(settings.microBreakSeconds)) + " " + L10n.resume + "。"
        promptEndsAt = Date().addingTimeInterval(settings.microBreakDuration)
        isMicroBreakPromptActive = true
        play(named: settings.soundName, volumeGain: 2.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.play(named: self.settings.soundName, volumeGain: 2.0)
        }
        notify(title: L10n.randomBell, body: L10n.closeYourEyes(seconds: Int(settings.microBreakSeconds)))
        microBreakNoticeController.show(seconds: settings.microBreakSeconds, accentColor: settings.accentColorChoice.color)
    }

    private func handlePromptEnd(at now: Date) {
        if isMicroBreakPromptActive {
            isMicroBreakPromptActive = false
            microBreakNoticeController.close()
            if settings.microBreakEndCueEnabled, phase == .focus {
                activePromptText = L10n.backToFocus
                promptEndsAt = now.addingTimeInterval(1.6)
                play(named: "Glass", volumeGain: 1.0)
                return
            }
        }

        activePromptText = nil
        promptEndsAt = nil
    }

    private func scheduleNextPing(from date: Date) {
        guard phase == .focus else {
            nextPingDate = nil
            return
        }
        let range = settings.pingMinDuration...settings.pingMaxDuration
        let offset = TimeInterval.random(in: range)
        let candidate = date.addingTimeInterval(offset)
        if let phaseEndDate, candidate >= phaseEndDate {
            nextPingDate = nil
        } else {
            nextPingDate = candidate
        }
    }

    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func startApplicationObservers() {
        let center = NSWorkspace.shared.notificationCenter
        let names: [Notification.Name] = [
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didUnhideApplicationNotification
        ]

        workspaceObservers = names.map { name in
            center.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                let runningApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
                guard let self else { return }
                MainActor.assumeIsolated {
                    self.handleBlockedAppIfNeeded(runningApp: runningApp)
                }
            }
        }
    }

    private func stopApplicationObservers() {
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach { center.removeObserver($0) }
        workspaceObservers.removeAll()
    }

    func cleanup() {
        timer?.invalidate()
        timer = nil
        stopApplicationObservers()
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func handleBlockedAppIfNeeded(runningApp app: NSRunningApplication?) {
        guard phase == .focus, isRunning else { return }
        guard let app else { return }
        let now = Date()
        guard let bundleID = app.bundleIdentifier, bundleID != Bundle.main.bundleIdentifier else {
            return
        }
        guard settings.blockedApps.contains(where: { $0.bundleIdentifier == bundleID }) else {
            return
        }
        guard !isBlockedAppTemporarilyAllowed(bundleID: bundleID, now: now) else {
            return
        }

        app.hide()
        if let lastShownAt = blockedNoticeLastShownAt[bundleID],
           now.timeIntervalSince(lastShownAt) < blockedNoticeCooldown {
            return
        }

        blockedNoticeLastShownAt[bundleID] = now
        let appName = app.localizedName ?? L10n.thisApp
        blockNoticeController.show(appName: appName, accentColor: settings.accentColorChoice.color) { [weak self] in
            Task { @MainActor in
                self?.allowBlockedAppTemporarily(bundleID: bundleID)
            }
        }
    }

    private func enforceBlockedFrontmostAppIfNeeded() {
        handleBlockedAppIfNeeded(runningApp: NSWorkspace.shared.frontmostApplication)
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request)
    }

    private var audioPlayer: AVAudioPlayer?

    private func play(named soundName: String, volumeGain: Float = 1.0) {
        // 停止之前的播放
        audioPlayer?.stop()

        // 系统声音路径
        let soundPath = "/System/Library/Sounds/\(soundName).aiff"
        let url = URL(fileURLWithPath: soundPath)

        guard FileManager.default.fileExists(atPath: soundPath) else {
            // 如果文件不存在，回退到 NSSound
            let sound = NSSound(named: NSSound.Name(soundName))
            sound?.volume = min(volumeGain, 1.0)
            sound?.play()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            // volumeGain > 1.0 时可以增强音量（但可能失真）
            audioPlayer?.volume = min(volumeGain, 3.0)
            audioPlayer?.play()
        } catch {
            // 回退到 NSSound
            let sound = NSSound(named: NSSound.Name(soundName))
            sound?.volume = min(volumeGain, 1.0)
            sound?.play()
        }
    }

    private func isBlockedAppTemporarilyAllowed(bundleID: String, now: Date) -> Bool {
        guard let until = temporarilyAllowedUntil[bundleID] else {
            return false
        }
        return until > now
    }

    private func pruneTemporaryAllowances(at now: Date) {
        let active = temporarilyAllowedUntil.filter { $0.value > now }
        if active.count != temporarilyAllowedUntil.count {
            temporarilyAllowedUntil = active
            temporarilyAllowedBundleIDs = Set(active.keys)
        }
    }

    func timeLabel() -> String {
        if phase == .idle {
            return shortTime(settings.focusDuration)
        }
        return shortTime(secondsRemaining)
    }

    private var microBreakCountdownTitle: String {
        guard let promptEndsAt else {
            return shortTime(settings.microBreakDuration)
        }
        let remaining = max(0, promptEndsAt.timeIntervalSinceNow)
        return shortTime(remaining)
    }

    func progressValue() -> Double {
        let total: TimeInterval
        switch phase {
        case .focus:
            total = settings.focusDuration
        case .rest:
            total = settings.breakDuration
        case .idle:
            return 0
        }
        guard total > 0 else { return 0 }
        return min(max(1 - secondsRemaining / total, 0), 1)
    }

    func nextPingLabel() -> String {
        if isMicroBreakPromptActive {
            return L10n.microBreakInProgress
        }
        guard phase == .focus else {
            return ""
        }
        guard isRunning else {
            return L10n.randomBellPaused
        }
        guard nextPingDate != nil else {
            return L10n.noNewBellScheduled
        }
        return L10n.randomBellActive(range: pingWindowLabel())
    }

    private func pingWindowLabel() -> String {
        let minText = intervalText(settings.pingMinMinutes)
        let maxText = intervalText(settings.pingMaxMinutes)
        if minText == maxText {
            return L10n.aroundTime(time: minText)
        }
        return L10n.timeRange(min: minText, max: maxText)
    }

    private func intervalText(_ value: Double) -> String {
        if value.rounded() == value {
            return L10n.minutesInt(minutes: Int(value))
        }
        return L10n.minutesFloat(minutes: value)
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
}
