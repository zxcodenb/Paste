import SwiftUI

enum PanelPage {
    case history
    case settings
}

struct PanelRootView: View {
    @State private var page: PanelPage
    @ObservedObject var store: ClipboardStore
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager
    @ObservedObject var appearanceManager: AppearanceManager
    let historyLimit: Int
    let onSelect: (ClipboardItem) -> Void
    let onClearHistory: () -> Void
    let onPageChanged: (PanelPage) -> Void
    let onClose: () -> Void
    let sourceAppResolver: any SourceAppResolving

    @Environment(\.colorScheme) private var colorScheme

    init(
        initialPage: PanelPage,
        store: ClipboardStore,
        launchAtLoginManager: LaunchAtLoginManager,
        appearanceManager: AppearanceManager,
        historyLimit: Int,
        onSelect: @escaping (ClipboardItem) -> Void,
        onClearHistory: @escaping () -> Void,
        onPageChanged: @escaping (PanelPage) -> Void,
        onClose: @escaping () -> Void,
        sourceAppResolver: any SourceAppResolving
    ) {
        _page = State(initialValue: initialPage)
        _store = ObservedObject(wrappedValue: store)
        _launchAtLoginManager = ObservedObject(wrappedValue: launchAtLoginManager)
        _appearanceManager = ObservedObject(wrappedValue: appearanceManager)
        self.historyLimit = historyLimit
        self.onSelect = onSelect
        self.onClearHistory = onClearHistory
        self.onPageChanged = onPageChanged
        self.onClose = onClose
        self.sourceAppResolver = sourceAppResolver
    }

    var body: some View {
        switch page {
        case .history:
            HistoryPanelView(
                store: store,
                onSelect: onSelect,
                onClear: onClearHistory,
                onOpenSettings: {
                    page = .settings
                    onPageChanged(.settings)
                },
                onClose: onClose,
                sourceAppResolver: sourceAppResolver
            )
            .preferredColorScheme(appearanceManager.resolvedColorScheme)
        case .settings:
            settingsPage
        }
    }

    private var settingsPage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ThemeColors.backgroundGradientStart(colorScheme),
                    ThemeColors.backgroundGradientEnd(colorScheme)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button {
                        page = .history
                        onPageChanged(.history)
                    } label: {
                        Label("返回", systemImage: "chevron.left")
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("设置")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("关闭")
                }
                .padding(.horizontal, 4)

                SettingsView(
                    store: store,
                    launchAtLoginManager: launchAtLoginManager,
                    appearanceManager: appearanceManager,
                    historyLimit: historyLimit,
                    onClearHistory: onClearHistory
                )
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(ThemeColors.cardFill(colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(ThemeColors.cardBorder(colorScheme), lineWidth: 0.5)
                )
                .shadow(color: ThemeColors.shadow(colorScheme), radius: 16, y: 6)
            }
            .padding(14)
        }
        .preferredColorScheme(appearanceManager.resolvedColorScheme)
        .frame(minWidth: 620, minHeight: 500)
    }
}
