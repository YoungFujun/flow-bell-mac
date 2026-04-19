import AppKit
import SwiftUI

// 自定义 Panel，可以成为 key window 以接收键盘输入
class TaskPromptPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class TaskPromptController {
    private var panel: TaskPromptPanel?
    private var model: TaskPromptModel?
    private var menuBarWindow: NSWindow?
    private var otherWindows: [NSWindow] = []
    private static let panelWidth: CGFloat = 380
    private static let panelHeight: CGFloat = 200

    func show(accentColor: Color, defaultTaskText: String, onStart: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        let model = TaskPromptModel(
            accentColor: accentColor,
            defaultTaskText: defaultTaskText,
            onStart: { text in
                onStart(text)
                self.closeWithoutShowingMenuBar() // 计时开始，不恢复主界面
            },
            onCancel: {
                onCancel()
                self.closeWithoutShowingMenuBar() // 取消，也不恢复主界面
            }
        )
        self.model = model

        if panel == nil {
            let panel = TaskPromptPanel(
                contentRect: NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.panelHeight),
                styleMask: [.borderless, .resizable],
                backing: .buffered,
                defer: false
            )
            panel.level = .floating
            panel.isFloatingPanel = true
            panel.hidesOnDeactivate = false
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isMovableByWindowBackground = true
            panel.contentView = NSHostingView(rootView: TaskPromptView(model: model))
            panel.contentView?.wantsLayer = true
            panel.contentView?.layer?.cornerRadius = 16
            panel.contentView?.layer?.masksToBounds = true
            self.panel = panel
        } else {
            panel?.contentView = NSHostingView(rootView: TaskPromptView(model: model))
        }

        // 临时隐藏所有应用窗口
        hideMenuBarWindow()
        positionPanel()
        // 激活应用，确保窗口可以接收键盘输入
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel?.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel?.orderOut(nil)
        model = nil
        // 恢复菜单栏主界面窗口
        showMenuBarWindow()
    }

    func closeWithoutShowingMenuBar() {
        panel?.orderOut(nil)
        model = nil
        otherWindows = [] // 清空窗口列表，避免下次使用时状态不一致
    }

    private func hideMenuBarWindow() {
        // 隐藏所有应用窗口（除了我们创建的 panel）
        otherWindows = []
        for window in NSApplication.shared.windows {
            if window !== panel {
                otherWindows.append(window)
                window.orderOut(nil)
            }
        }
    }

    private func showMenuBarWindow() {
        // 恢复所有应用窗口
        for window in otherWindows {
            window.orderFront(nil)
        }
        otherWindows = []
    }

    private func positionPanel() {
        // 定位在屏幕中央偏上，确保不被主界面遮挡
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let screenFrame = screen.visibleFrame

        // 将输入框放在屏幕中央，略微偏上
        let origin = NSPoint(
            x: screenFrame.midX - Self.panelWidth / 2,
            y: screenFrame.midY + Self.panelHeight / 2 + 50 // 中央偏上 50px
        )
        panel?.setFrameOrigin(origin)
    }
}

@MainActor
final class TaskPromptModel: ObservableObject {
    @Published var taskText: String
    let accentColor: Color
    let onStart: (String) -> Void
    let onCancel: () -> Void

    init(accentColor: Color, defaultTaskText: String, onStart: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.accentColor = accentColor
        self.taskText = defaultTaskText
        self.onStart = onStart
        self.onCancel = onCancel
    }
}

struct TaskPromptView: View {
    @ObservedObject var model: TaskPromptModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            // 标题
            Text(L10n.taskPromptTitle)
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)

            TextField(L10n.taskPromptPlaceholder, text: $model.taskText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.08))
                )
                .frame(width: 320)
                .focused($isInputFocused)
                .onSubmit {
                    // 回车键触发开始
                    model.onStart(model.taskText)
                }

            HStack(spacing: 16) {
                Button(L10n.cancel) {
                    model.onCancel()
                }
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)

                Button(L10n.start) {
                    model.onStart(model.taskText)
                }
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(model.accentColor)
                )
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .onExitCommand {
            // ESC 键触发取消
            model.onCancel()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
    }
}