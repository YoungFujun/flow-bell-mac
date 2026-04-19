import AppKit
import SwiftUI

@MainActor
final class MicroBreakNoticeController {
    private let model = MicroBreakNoticeModel()
    private var panel: NSPanel?

    func show(seconds: Double, accentColor: Color = .accentColor) {
        model.secondsRemaining = seconds
        model.accentColor = accentColor

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 180, height: 56),
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
            x: frame.midX - 90,
            y: frame.maxY - 76
        )
        panel?.setFrameOrigin(origin)
    }
}

@MainActor
final class MicroBreakNoticeModel: ObservableObject {
    @Published var secondsRemaining: Double = 0
    @Published var accentColor: Color = .accentColor

    var countdownText: String {
        let s = max(0, Int(secondsRemaining.rounded(.up)))
        return L10n.secondsLabel(seconds: s)
    }
}

private struct MicroBreakNoticeView: View {
    @ObservedObject var model: MicroBreakNoticeModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(model.accentColor)
                .frame(width: 20)

            Text(L10n.closeEyesRest(seconds: Int(model.secondsRemaining.rounded(.up))))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 180, height: 56)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}