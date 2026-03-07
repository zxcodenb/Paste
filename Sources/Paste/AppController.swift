import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppController: ObservableObject {
    let store: ClipboardStore
    let launchAtLoginManager: LaunchAtLoginManager

    private let clipboardMonitor: ClipboardMonitor
    private let hotkeyManager: HotkeyManager
    private let pasteboardWriter: any PasteboardWriting
    private var didStart = false

    private lazy var panelController = PanelController { [weak self] in
        guard let self else {
            return AnyView(EmptyView())
        }

        return AnyView(
            HistoryPanelView(
                store: self.store,
                onSelect: { [weak self] item in
                    self?.handleSelection(item)
                },
                onClear: { [weak self] in
                    self?.clearHistory()
                },
                onClose: { [weak self] in
                    self?.hideHistoryPanel()
                }
            )
        )
    }

    init(
        store: ClipboardStore = ClipboardStore(),
        launchAtLoginManager: LaunchAtLoginManager = LaunchAtLoginManager(),
        clipboardMonitor: ClipboardMonitor = ClipboardMonitor(),
        hotkeyManager: HotkeyManager = HotkeyManager(),
        pasteboardWriter: any PasteboardWriting = SystemPasteboardWriter()
    ) {
        self.store = store
        self.launchAtLoginManager = launchAtLoginManager
        self.clipboardMonitor = clipboardMonitor
        self.hotkeyManager = hotkeyManager
        self.pasteboardWriter = pasteboardWriter

        self.clipboardMonitor.onTextCopied = { [weak self] text, sourceBundleId in
            self?.store.addFromPasteboard(text, sourceAppBundleId: sourceBundleId)
        }

        self.hotkeyManager.onTogglePanel = { [weak self] in
            self?.toggleHistoryPanel()
        }

    }

    func start() {
        guard !didStart else {
            return
        }

        didStart = true
        store.load()
        clipboardMonitor.start()
        hotkeyManager.registerTogglePanelHotkey()
    }

    func stop() {
        clipboardMonitor.stop()
        hotkeyManager.unregister()
        store.save()
    }

    func openHistoryPanel() {
        panelController.show()
    }

    func hideHistoryPanel() {
        panelController.hide()
    }

    func toggleHistoryPanel() {
        panelController.toggle()
    }

    func clearHistory() {
        store.clear()
    }

    private func handleSelection(_ item: ClipboardItem) {
        clipboardMonitor.ignoreNextChange()
        pasteboardWriter.writeText(item.content)
        hideHistoryPanel()
    }
}
