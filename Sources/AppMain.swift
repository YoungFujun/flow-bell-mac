import AppKit
import Combine
import SwiftUI

@main
struct FlowRandomBellApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var preferences = PreferencesStore()
    @StateObject private var engine = FocusEngine()
    @StateObject private var installedApps = InstalledAppsStore()
    @StateObject private var dailyStats = DailyStatsStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(preferences)
                .environmentObject(engine)
                .environmentObject(installedApps)
                .environmentObject(dailyStats)
                .frame(width: 360)
                .onAppear {
                    engine.configure(preferences: preferences)
                    engine.dailyStats = dailyStats
                }
                .onReceive(preferences.$settings.removeDuplicates()) { updated in
                    engine.apply(settings: updated)
                }
        } label: {
            MenuBarLabelView(
                style: preferences.settings.menuBarDisplayStyle,
                title: engine.menuBarTitle,
                idleTitle: String(format: "%02d:00", Int(preferences.settings.focusMinutes)),
                progress: engine.progressValue(),
                phase: engine.phase,
                isRunning: engine.isRunning,
                showMicroBreakCountdown: engine.isShowingMicroBreakCountdown
            )
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

private struct MenuBarLabelView: View {
    let style: MenuBarDisplayStyle
    let title: String
    let idleTitle: String
    let progress: Double
    let phase: FocusEngine.Phase
    let isRunning: Bool
    let showMicroBreakCountdown: Bool

    var displayText: String {
        if showMicroBreakCountdown { return title }
        return phase == .idle ? idleTitle : title
    }

    var body: some View {
        if showMicroBreakCountdown || style == .digital {
            Text(displayText)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 5)
                .padding(.vertical, 1.5)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                )
        } else {
            StatusRingView(phase: phase, isRunning: isRunning, progress: progress)
                .frame(width: 22, height: 22)
        }
    }
}

private struct StatusRingView: View {
    let phase: FocusEngine.Phase
    let isRunning: Bool
    let progress: Double

    var span: Double {
        switch phase {
        case .idle: return 0.12
        case .focus, .rest: return max(progress, 0.04)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.18), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: span)
                .stroke(
                    Color.primary.opacity(isRunning ? 1.0 : 0.55),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}
