import AppKit
import SwiftUI

@MainActor
final class BlockNoticeController {
    private let model = BlockNoticeModel()
    private var panel: NSPanel?
    private var dismissWorkItem: DispatchWorkItem?

    func show(appName: String, accentColor: Color = .accentColor, onAllowTemporarily: (() -> Void)? = nil) {
        model.appName = appName
        model.actionTitle = onAllowTemporarily == nil ? nil : L10n.allow5Min
        model.accentColor = accentColor
        model.action = { [weak self] in
            onAllowTemporarily?()
            self?.close()
        }

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 60),
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
            panel.contentView = NSHostingView(rootView: BlockNoticeView(model: model))
            self.panel = panel
        }

        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let frame = screen.visibleFrame
            let origin = NSPoint(
                x: frame.midX - 160,
                y: frame.maxY - 80
            )
            panel?.setFrameOrigin(origin)
        }

        panel?.orderFrontRegardless()

        dismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.panel?.orderOut(nil)
        }
        dismissWorkItem = workItem
        let dismissDelay = onAllowTemporarily == nil ? 1.5 : 4.0
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay, execute: workItem)
    }

    func close() {
        dismissWorkItem?.cancel()
        panel?.orderOut(nil)
        model.action = nil
    }
}

@MainActor
final class BlockNoticeModel: ObservableObject {
    @Published var appName = ""
    @Published var actionTitle: String?
    @Published var accentColor: Color = .accentColor
    var action: (() -> Void)?
}

private struct BlockNoticeView: View {
    @ObservedObject var model: BlockNoticeModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "app.badge.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(model.accentColor)
                .frame(width: 20)

            Text(L10n.blockedAppName(name: model.appName))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            if let actionTitle = model.actionTitle {
                Button(actionTitle) {
                    model.action?()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(model.accentColor)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 320, height: 60)
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