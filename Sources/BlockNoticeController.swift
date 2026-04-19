import AppKit
import SwiftUI

@MainActor
final class BlockNoticeController {
    private let model = BlockNoticeModel()
    private var panel: NSPanel?
    private var dismissWorkItem: DispatchWorkItem?

    func show(appName: String, onAllowTemporarily: (() -> Void)? = nil) {
        model.message = "专注中，已隐藏 \(appName)"
        model.actionTitle = onAllowTemporarily == nil ? nil : "放行 5 分钟"
        model.action = { [weak self] in
            onAllowTemporarily?()
            self?.close()
        }

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 96),
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
                x: frame.midX - 150,
                y: frame.maxY - 120
            )
            panel?.setFrameOrigin(origin)
        }

        panel?.orderFrontRegardless()

        dismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.panel?.orderOut(nil)
        }
        dismissWorkItem = workItem
        let dismissDelay = onAllowTemporarily == nil ? 1.1 : 3.0
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay, execute: workItem)
    }

    func close() {
        dismissWorkItem?.cancel()
        panel?.orderOut(nil)
    }
}

@MainActor
final class BlockNoticeModel: ObservableObject {
    @Published var message = ""
    @Published var actionTitle: String?
    var action: (() -> Void)?
}

private struct BlockNoticeView: View {
    @ObservedObject var model: BlockNoticeModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(model.message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let actionTitle = model.actionTitle {
                    Button(actionTitle) {
                        model.action?()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white)
                    )
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 300, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.82))
        )
        .padding(6)
    }
}
