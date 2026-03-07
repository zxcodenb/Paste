import AppKit
import SwiftUI

@MainActor
final class PanelController {
    private let makeRootView: () -> AnyView
    private var panel: NSPanel?

    init(makeRootView: @escaping () -> AnyView) {
        self.makeRootView = makeRootView
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        let panel = ensurePanel()
        panel.contentView = NSHostingView(rootView: makeRootView())
        position(panel: panel)
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func ensurePanel() -> NSPanel {
        if let panel {
            return panel
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        self.panel = panel
        return panel
    }

    private func position(panel: NSPanel) {
        let screen = NSApplication.shared.keyWindow?.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else {
            return
        }

        let visibleFrame = screen.visibleFrame
        let width = panel.frame.width
        let height = panel.frame.height
        let x = visibleFrame.midX - (width / 2)
        let y = visibleFrame.maxY - height - 80
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
