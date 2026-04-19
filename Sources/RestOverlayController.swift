import AppKit
import SwiftUI

@MainActor
final class RestOverlayController {
    private let model = RestOverlayModel()
    private var panel: NSPanel?

    private static let panelWidth: CGFloat = 320
    private static let panelHeight: CGFloat = 220

    func show(secondsRemaining: TimeInterval, onSkip: @escaping () -> Void) {
        model.onSkip = onSkip
        model.secondsRemaining = secondsRemaining

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

        positionPanel()
        panel?.orderFrontRegardless()
    }

    func update(secondsRemaining: TimeInterval) {
        model.secondsRemaining = secondsRemaining
    }

    func close() {
        panel?.orderOut(nil)
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
}

@MainActor
final class RestOverlayModel: ObservableObject {
    @Published var secondsRemaining: TimeInterval = 0
    var onSkip: (() -> Void)?

    var timeText: String {
        let total = Int(secondsRemaining.rounded(.down))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct RestOverlayView: View {
    @ObservedObject var model: RestOverlayModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.72))
                Text("休息一下")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                Spacer()
            }

            Text(model.timeText)
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("离开屏幕、放松眼睛。")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("提前结束休息") {
                model.onSkip?()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .trailing)
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
