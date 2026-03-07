import SwiftUI

struct HistoryPanelView: View {
    @ObservedObject var store: ClipboardStore
    let onSelect: (ClipboardItem) -> Void
    let onClear: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if store.items.isEmpty {
                ContentUnavailableView("No Clipboard History", systemImage: "clipboard")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(store.items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.content)
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(item.copiedAt, format: .dateTime.hour().minute().second())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .help(item.content)
                }
                .listStyle(.plain)
            }
        }
        .padding(12)
        .frame(minWidth: 520, minHeight: 360)
    }

    private var header: some View {
        HStack {
            Text("Clipboard History")
                .font(.headline)

            Spacer()

            Button("Clear") {
                onClear()
            }
            .disabled(store.items.isEmpty)

            Button("Close") {
                onClose()
            }
            .keyboardShortcut(.cancelAction)
        }
    }
}
