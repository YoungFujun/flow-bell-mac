import AppKit
import SwiftUI

@MainActor
final class MicroBreakNoticeController {
    private let model = MicroBreakNoticeModel()
    private var panel: NSPanel?

    func show(seconds: Double) {
        model.secondsRemaining = seconds

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 280, height: 90),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = .statusBar
            panel.isFloatingPanel = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: MicroBreakNoticeView(model: model))
            self.panel = panel
        }

        positionPanel()
        panel?.orderFrontRegardless()
    }

    func update(secondsRemaining: Double) {
        model.secondsRemaining = secondsRemaining
    }

    func close() {
        panel?.orderOut(nil)
    }

    private func positionPanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = screen.visibleFrame
        let origin = NSPoint(
            x: frame.midX - 140,
            y: frame.maxY - 120
        )
        panel?.setFrameOrigin(origin)
    }
}

@MainActor
final class MicroBreakNoticeModel: ObservableObject {
    @Published var secondsRemaining: Double = 0

    var countdownText: String {
        let s = max(0, Int(secondsRemaining.rounded(.up)))
        return "\(s)"
    }
}

private struct MicroBreakNoticeView: View {
    @ObservedObject var model: MicroBreakNoticeModel

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("闭眼微休息")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                Text(model.countdownText + " 秒")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(width: 280, height: 90, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.82))
        )
        .padding(6)
    }
}
