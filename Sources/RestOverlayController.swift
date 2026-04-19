import AppKit
import SwiftUI

@MainActor
final class RestOverlayController {
    private let model = RestOverlayModel()
    private var panel: NSPanel?
    private var miniPanel: NSPanel?
    private var isMinimized = false

    private static let panelWidth: CGFloat = 320
    private static let panelHeight: CGFloat = 220
    private static let miniPanelWidth: CGFloat = 160
    private static let miniPanelHeight: CGFloat = 56

    func show(secondsRemaining: TimeInterval, accentColor: Color = .accentColor, onSkip: @escaping () -> Void, onNextFocus: @escaping () -> Void) {
        model.secondsRemaining = secondsRemaining
        model.isMinimized = false
        model.accentColor = accentColor
        model.onClose = { [weak self] in self?.close() }
        model.onMinimize = { [weak self] in self?.minimize() }
        model.onSkip = { [weak self] in
            onSkip()
            self?.close()
        }
        model.onNextFocus = { [weak self] in
            onNextFocus()
            self?.close()
        }
        model.onExpand = { [weak self] in self?.expand() }

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.panelHeight),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = .floating
            panel.isFloatingPanel = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: RestOverlayView(model: model))
            self.panel = panel
        }

        if miniPanel == nil {
            let miniPanel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: Self.miniPanelWidth, height: Self.miniPanelHeight),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            miniPanel.level = .statusBar
            miniPanel.isFloatingPanel = true
            miniPanel.backgroundColor = .clear
            miniPanel.isOpaque = false
            miniPanel.hasShadow = true
            miniPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            miniPanel.contentView = NSHostingView(rootView: RestMiniView(model: model))
            self.miniPanel = miniPanel
        }

        positionPanel()
        positionMiniPanel()
        panel?.orderFrontRegardless()
        miniPanel?.orderOut(nil)
        isMinimized = false
    }

    func update(secondsRemaining: TimeInterval) {
        model.secondsRemaining = secondsRemaining
    }

    func close() {
        panel?.orderOut(nil)
        miniPanel?.orderOut(nil)
        isMinimized = false
        model.isMinimized = false
        model.clearCallbacks()
    }

    private func minimize() {
        panel?.orderOut(nil)
        positionMiniPanel()
        miniPanel?.orderFrontRegardless()
        isMinimized = true
        model.isMinimized = true
    }

    private func expand() {
        miniPanel?.orderOut(nil)
        positionPanel()
        panel?.orderFrontRegardless()
        isMinimized = false
        model.isMinimized = false
    }

    private func positionPanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = screen.visibleFrame
        let origin = NSPoint(
            x: frame.midX - Self.panelWidth / 2,
            y: frame.maxY - Self.panelHeight - 20
        )
        panel?.setFrameOrigin(origin)
    }

    private func positionMiniPanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = screen.visibleFrame
        let origin = NSPoint(
            x: frame.midX - Self.miniPanelWidth / 2,
            y: frame.maxY - Self.miniPanelHeight - 16
        )
        miniPanel?.setFrameOrigin(origin)
    }
}

@MainActor
final class RestOverlayModel: ObservableObject {
    @Published var secondsRemaining: TimeInterval = 0
    @Published var isMinimized = false
    @Published var accentColor: Color = .accentColor
    var onClose: (() -> Void)?
    var onMinimize: (() -> Void)?
    var onSkip: (() -> Void)?
    var onNextFocus: (() -> Void)?
    var onExpand: (() -> Void)?

    var timeText: String {
        let total = Int(secondsRemaining.rounded(.down))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var miniTimeText: String {
        let total = Int(secondsRemaining.rounded(.down))
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "\(seconds)s"
    }

    func clearCallbacks() {
        onClose = nil
        onMinimize = nil
        onSkip = nil
        onNextFocus = nil
        onExpand = nil
    }
}

struct RestOverlayView: View {
    @ObservedObject var model: RestOverlayModel

    var body: some View {
        VStack(spacing: 20) {
            // 关闭按钮保持在右上角
            HStack {
                Spacer()
                Button(action: { model.onClose?() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.72))

                Text(L10n.restAWhile)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
            }

            Text(model.timeText)
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            Text(L10n.stepAwayFromScreen)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.55))

            HStack(spacing: 8) {
                Button(L10n.minimize) {
                    model.onMinimize?()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
                .frame(width: 72)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

                Button(L10n.endRest) {
                    model.onSkip?()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
                .frame(width: 72)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

                Button(L10n.nextFocus) {
                    model.onNextFocus?()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
                .frame(width: 72)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(24)
        .frame(width: 320, height: 220)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.88))
        )
        .padding(8)
    }
}

private struct RestMiniView: View {
    @ObservedObject var model: RestOverlayModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(model.accentColor)
                .frame(width: 20)

            Text(L10n.restTime(time: model.miniTimeText))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 160, height: 56)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .onTapGesture {
            model.onExpand?()
        }
    }
}