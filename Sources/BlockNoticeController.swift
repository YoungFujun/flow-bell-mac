import AppKit
import SwiftUI

@MainActor
final class BlockNoticeController {
    private let model = BlockNoticeModel()
    private var panel: NSPanel?
    private var dismissWorkItem: DispatchWorkItem?

    func show(appName: String) {
        model.message = "专注中，已拦截 \(appName)"

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 280, height: 74),
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
                x: frame.midX - 140,
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1, execute: workItem)
    }
}

@MainActor
final class BlockNoticeModel: ObservableObject {
    @Published var message = ""
}

private struct BlockNoticeView: View {
    @ObservedObject var model: BlockNoticeModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            Text(model.message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 18)
        .frame(width: 280, height: 74, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.82))
        )
        .padding(6)
    }
}
