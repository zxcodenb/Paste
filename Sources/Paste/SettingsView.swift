import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: ClipboardStore
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager
    let historyLimit: Int
    let onClearHistory: () -> Void

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { launchAtLoginManager.isEnabled },
                    set: { launchAtLoginManager.setEnabled($0) }
                ))

                HStack {
                    Text("Hotkey")
                    Spacer()
                    Text("Option + Space")
                        .foregroundStyle(.secondary)
                }
            }

            Section("History") {
                HStack {
                    Text("Current Items")
                    Spacer()
                    Text("\(store.items.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Max Items")
                    Spacer()
                    Text("\(historyLimit)")
                        .foregroundStyle(.secondary)
                }

                Button("Clear History", role: .destructive) {
                    onClearHistory()
                }
                .disabled(store.items.isEmpty)
            }

            if let errorMessage = launchAtLoginManager.errorMessage {
                Section("Service") {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(16)
        .frame(width: 420)
    }
}
