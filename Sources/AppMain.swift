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

    var body: some View {
        if showMicroBreakCountdown {
            Image(nsImage: ClockBoxImage.make(text: title))
                .interpolation(.high)
        } else {
            switch style {
            case .digital:
                Image(nsImage: ClockBoxImage.make(text: phase == .idle ? idleTitle : title))
                    .interpolation(.high)
            case .ring:
                Image(nsImage: StatusRingImage.make(
                    phase: phase,
                    isRunning: isRunning,
                    progress: progress
                ))
                .interpolation(.high)
            }
        }
    }
}

private enum ClockBoxImage {
    static func make(text: String) -> NSImage {
        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let textSize = str.size()

        let hPad: CGFloat = 5
        let vPad: CGFloat = 2
        let size = NSSize(width: textSize.width + hPad * 2, height: textSize.height + vPad * 2)
        let image = NSImage(size: size)
        image.lockFocus()

        // border
        let borderRect = NSRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
        let path = NSBezierPath(roundedRect: borderRect, xRadius: 3, yRadius: 3)
        path.lineWidth = 1
        NSColor.secondaryLabelColor.setStroke()
        path.stroke()

        // text
        let textOrigin = NSPoint(x: hPad, y: vPad)
        str.draw(at: textOrigin)

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}

private enum StatusRingImage {
    static func make(
        phase: FocusEngine.Phase,
        isRunning: Bool,
        progress: Double
    ) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)
        let ringRect = rect.insetBy(dx: 3, dy: 3)
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = ringRect.width / 2

        // track ring
        NSColor(calibratedWhite: 0.18, alpha: 0.18).setStroke()
        let baseRing = NSBezierPath(ovalIn: ringRect)
        baseRing.lineWidth = 2.5
        baseRing.stroke()

        let elapsed = max(0, min(1, progress))
        let span: Double
        switch phase {
        case .idle:
            span = 0.12
        case .focus, .rest:
            span = max(elapsed, 0.04)
        }

        // progress arc
        let arc = NSBezierPath()
        arc.appendArc(
            withCenter: center,
            radius: radius,
            startAngle: 90,
            endAngle: 90 - (360 * span),
            clockwise: true
        )
        arc.lineWidth = 2.5
        arc.lineCapStyle = .round
        NSColor(calibratedWhite: 0.08, alpha: isRunning ? 1.0 : 0.55).setStroke()
        arc.stroke()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
