import SwiftUI

struct HistoryPanelView: View {
    @ObservedObject var store: ClipboardStore
    let onSelect: (ClipboardItem) -> Void
    let onClear: () -> Void
    let onClose: () -> Void

    @State private var selectedItemID: ClipboardItem.ID?
    @FocusState private var isListFocused: Bool

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading, spacing: 14) {
                header
                keyboardHint

                if store.items.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.85), lineWidth: 0.5)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .allowsHitTesting(false)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 16, y: 6)
            .padding(14)
        }
        .preferredColorScheme(.light)
        .frame(minWidth: 620, minHeight: 500)
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color(red: 0.94, green: 0.96, blue: 1.0),
                Color(red: 0.91, green: 0.94, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Clipboard History")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Liquid glass style quick picker")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Copy") {
                selectCurrentItem()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.30, green: 0.53, blue: 0.95))
            .disabled(store.items.isEmpty || selectedItemID == nil)
            .keyboardShortcut(.defaultAction)

            Button("Clear") {
                onClear()
            }
            .buttonStyle(.bordered)
            .disabled(store.items.isEmpty)

            Button("Close") {
                onClose()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.cancelAction)
        }
    }

    private var keyboardHint: some View {
        HStack(spacing: 10) {
            Label("Up / Down", systemImage: "arrow.up.arrow.down")
            Text("Move")
            Label("Return", systemImage: "return.left")
            Text("Copy")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.5), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clipboard")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.secondary)
            Text("No Clipboard History")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            Text("Copy some text from any app, it will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
        )
    }

    private var historyList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(store.items) { item in
                        row(item)
                            .id(item.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedItemID = item.id
                                selectCurrentItem()
                            }
                            .help(item.content)
                    }
                }
                .padding(6)
            }
            .focusable()
            .focused($isListFocused)
            .onKeyPress(.upArrow) {
                moveSelection(by: -1)
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(selectedItemID, anchor: .center)
                }
                return .handled
            }
            .onKeyPress(.downArrow) {
                moveSelection(by: 1)
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(selectedItemID, anchor: .center)
                }
                return .handled
            }
            .onAppear {
                normalizeSelection()
                DispatchQueue.main.async {
                    isListFocused = true
                }
            }
            .onChange(of: store.items.map(\.id)) { _ in
                normalizeSelection()
            }
        }
    }

    private func row(_ item: ClipboardItem) -> some View {
        let isSelected = selectedItemID == item.id

        return HStack(spacing: 0) {
            // Left accent bar for selected state
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.primary.opacity(isSelected ? 0.7 : 0))
                .frame(width: 3)
                .padding(.vertical, 6)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.content)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.copiedAt, format: .dateTime.hour().minute().second())
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.leading, 10)
            .padding(.trailing, 12)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(isSelected ? 0.55 : 0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    Color.white.opacity(isSelected ? 0.8 : 0.45),
                    lineWidth: 0.5
                )
        )
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .shadow(color: Color.black.opacity(isSelected ? 0.07 : 0.02), radius: isSelected ? 6 : 2, y: 2)
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }

    private func moveSelection(by step: Int) {
        guard !store.items.isEmpty else {
            selectedItemID = nil
            return
        }

        guard let selectedItemID,
              let currentIndex = store.items.firstIndex(where: { $0.id == selectedItemID }) else {
            self.selectedItemID = store.items.first?.id
            return
        }

        let nextIndex = min(max(currentIndex + step, 0), store.items.count - 1)
        self.selectedItemID = store.items[nextIndex].id
    }

    private func normalizeSelection() {
        guard !store.items.isEmpty else {
            selectedItemID = nil
            return
        }

        if let selectedItemID,
           store.items.contains(where: { $0.id == selectedItemID }) {
            return
        }

        selectedItemID = store.items.first?.id
    }

    private func selectCurrentItem() {
        guard let selectedItemID,
              let item = store.items.first(where: { $0.id == selectedItemID }) else {
            return
        }

        onSelect(item)
    }
}
