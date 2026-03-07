import AppKit
import SwiftUI

@main
@MainActor
struct PasteApp: App {
    @StateObject private var controller: AppController

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        let appController = AppController()
        _controller = StateObject(wrappedValue: appController)
        appController.start()
    }

    var body: some Scene {
        MenuBarExtra("Paste", systemImage: "doc.on.clipboard") {
            MenuBarContentView(
                store: controller.store,
                launchAtLoginManager: controller.launchAtLoginManager,
                onOpenHistory: controller.openHistoryPanel,
                onClearHistory: controller.clearHistory
            )
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(
                store: controller.store,
                launchAtLoginManager: controller.launchAtLoginManager,
                historyLimit: controller.store.maxItems,
                onClearHistory: controller.clearHistory
            )
        }
    }
}
