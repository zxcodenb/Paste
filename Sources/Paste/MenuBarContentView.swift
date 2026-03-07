import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: ClipboardStore
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager

    let onOpenHistory: () -> Void
    let onClearHistory: () -> Void

    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Open History") {
            onOpenHistory()
        }

        Button("Clear History") {
            onClearHistory()
        }
        .disabled(store.items.isEmpty)

        Divider()

        Toggle("Launch at Login", isOn: Binding(
            get: { launchAtLoginManager.isEnabled },
            set: { launchAtLoginManager.setEnabled($0) }
        ))

        Divider()

        Button("Settings") {
            openSettings()
        }

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
