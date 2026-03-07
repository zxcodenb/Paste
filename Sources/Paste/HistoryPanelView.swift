import AppKit
import SwiftUI

struct HistoryPanelView: View {
    private enum HistoryFilter: String, CaseIterable, Identifiable {
        case all
        case text
        case image
        case favorites

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:
                return "All"
            case .text:
                return "Text"
            case .image:
                return "Image"
            case .favorites:
                return "Favorites"
            }
        }
    }

    @ObservedObject var store: ClipboardStore
    let onSelect: (ClipboardItem) -> Void
    let onClear: () -> Void
    let onClose: () -> Void

    @State private var selectedFilter: HistoryFilter = .all
    @State private var selectedItemID: ClipboardItem.ID?
    @FocusState private var isListFocused: Bool

    private var filteredItems: [ClipboardItem] {
        switch selectedFilter {
        case .all:
            return store.items
        case .text:
            return store.items.filter { $0.category == .text }
        case .image:
            return store.items.filter { $0.category == .image }
        case .favorites:
            return store.items.filter(\.isFavorite)
        }
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading, spacing: 14) {
                header
                filterBar
                keyboardHint

                if filteredItems.isEmpty {
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
            .disabled(filteredItems.isEmpty || selectedItemID == nil)
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

    private var filterBar: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(HistoryFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("History Filter")
    }

    private var keyboardHint: some View {
        HStack(spacing: 10) {
            Label("Up / Down", systemImage: "arrow.up.arrow.down")
            Text("Move")
            Label("Left / Right", systemImage: "arrow.left.arrow.right")
            Text("Filter")
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
            if store.items.isEmpty {
                Text("Copy text or image from any app, it will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("No \(selectedFilter.title.lowercased()) items in current filter.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
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
                    ForEach(filteredItems) { item in
                        row(item)
                            .id(item.id)
                            .help(tooltip(for: item))
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
            .onKeyPress(.leftArrow) {
                moveFilter(by: -1)
                return .handled
            }
            .onKeyPress(.rightArrow) {
                moveFilter(by: 1)
                return .handled
            }
            .onAppear {
                normalizeSelection()
                DispatchQueue.main.async {
                    isListFocused = true
                }
            }
            .onChange(of: filteredItems.map(\.id)) {
                normalizeSelection()
            }
            .onChange(of: selectedFilter) {
                normalizeSelection()
            }
        }
    }

    private func row(_ item: ClipboardItem) -> some View {
        let isSelected = selectedItemID == item.id

        return HStack(spacing: 0) {
            HStack(spacing: 0) {
                // Left accent bar for selected state
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.primary.opacity(isSelected ? 0.7 : 0))
                    .frame(width: 3)
                    .padding(.vertical, 6)

                VStack(alignment: .leading, spacing: 8) {
                    categoryTag(item.category)

                    switch item.payload {
                    case let .text(text):
                        Text(text)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    case let .image(metadata):
                        HStack(alignment: .top, spacing: 10) {
                            imageThumbnail(for: item)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Image")
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundStyle(isSelected ? .primary : .secondary)
                                Text(imageMetaDescription(metadata))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text(item.copiedAt, format: .dateTime.hour().minute().second())
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
                .padding(.leading, 10)
                .padding(.trailing, 12)
                .padding(.vertical, 12)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedItemID = item.id
                selectCurrentItem()
            }

            favoriteButton(for: item)
                .padding(.trailing, 12)
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
        guard !filteredItems.isEmpty else {
            selectedItemID = nil
            return
        }

        guard let selectedItemID,
              let currentIndex = filteredItems.firstIndex(where: { $0.id == selectedItemID }) else {
            self.selectedItemID = filteredItems.first?.id
            return
        }

        let nextIndex = min(max(currentIndex + step, 0), filteredItems.count - 1)
        self.selectedItemID = filteredItems[nextIndex].id
    }

    private func moveFilter(by step: Int) {
        let filters = HistoryFilter.allCases
        guard let currentIndex = filters.firstIndex(of: selectedFilter) else {
            selectedFilter = .all
            return
        }

        let nextIndex = min(max(currentIndex + step, 0), filters.count - 1)
        selectedFilter = filters[nextIndex]
    }

    private func normalizeSelection() {
        guard !filteredItems.isEmpty else {
            selectedItemID = nil
            return
        }

        if let selectedItemID,
           filteredItems.contains(where: { $0.id == selectedItemID }) {
            return
        }

        selectedItemID = filteredItems.first?.id
    }

    private func selectCurrentItem() {
        guard let selectedItemID,
              let item = filteredItems.first(where: { $0.id == selectedItemID }) else {
            return
        }

        onSelect(item)
    }

    private func tooltip(for item: ClipboardItem) -> String {
        switch item.payload {
        case let .text(text):
            return text
        case let .image(metadata):
            return "Image \(pixelDescription(metadata)) · \(byteCountString(metadata.byteSize))"
        }
    }

    @ViewBuilder
    private func imageThumbnail(for item: ClipboardItem) -> some View {
        if let url = store.imageAssetURL(for: item),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                )
        }
    }

    private func imageMetaDescription(_ metadata: ClipboardItem.ImageMetadata) -> String {
        "\(pixelDescription(metadata)) · \(byteCountString(metadata.byteSize))"
    }

    private func pixelDescription(_ metadata: ClipboardItem.ImageMetadata) -> String {
        guard let width = metadata.pixelWidth, let height = metadata.pixelHeight else {
            return "Unknown size"
        }
        return "\(width)×\(height)"
    }

    private func byteCountString(_ byteCount: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }

    private func favoriteButton(for item: ClipboardItem) -> some View {
        Button {
            store.toggleFavorite(for: item.id)
        } label: {
            Image(systemName: item.isFavorite ? "star.fill" : "star")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(item.isFavorite ? Color.yellow : Color.secondary)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.5), in: Circle())
        }
        .buttonStyle(.plain)
        .help(item.isFavorite ? "Remove from favorites" : "Add to favorites")
    }

    private func categoryTag(_ category: ClipboardItem.Category) -> some View {
        Text(category == .text ? "Text" : "Image")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.55), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.7), lineWidth: 0.5)
            )
    }
}
