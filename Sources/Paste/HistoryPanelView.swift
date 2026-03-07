import SwiftUI

// MARK: - 历史面板视图
/// 显示剪贴板历史记录的列表视图
/// 支持选择、复制和清除操作
struct HistoryPanelView: View {
    /// 剪贴板存储
    @ObservedObject var store: ClipboardStore
    /// 选中项目回调
    let onSelect: (ClipboardItem) -> Void
    /// 清除历史回调
    let onClear: () -> Void
    /// 关闭面板回调
    let onClose: () -> Void
    /// 当前选中的项目 ID
    @State private var selectedItemID: ClipboardItem.ID?
    /// 列表焦点状态
    @FocusState private var isListFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            header

            if store.items.isEmpty {
                // 空状态提示
                ContentUnavailableView("No Clipboard History", systemImage: "clipboard")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 历史记录列表
                List(selection: $selectedItemID) {
                    ForEach(store.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            // 文本内容，最多显示两行
                            Text(item.content)
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // 复制时间
                            Text(item.copiedAt, format: .dateTime.hour().minute().second())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .tag(item.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItemID = item.id
                            selectCurrentItem()
                        }
                        .help(item.content)
                    }
                }
                .listStyle(.plain)
                .focused($isListFocused)
                .onAppear {
                    normalizeSelection()
                    DispatchQueue.main.async {
                        isListFocused = true
                    }
                }
                .onChange(of: store.items.map(\.id)) { _ in
                    normalizeSelection()
                }
                .onMoveCommand(perform: handleMoveCommand)
            }
        }
        .padding(12)
        .frame(minWidth: 520, minHeight: 360)
    }

    // MARK: - 头部视图
    private var header: some View {
        HStack {
            Text("Clipboard History")
                .font(.headline)

            Spacer()

            // 复制按钮
            Button("Copy") {
                selectCurrentItem()
            }
            .disabled(store.items.isEmpty || selectedItemID == nil)
            .keyboardShortcut(.defaultAction)

            // 清除按钮
            Button("Clear") {
                onClear()
            }
            .disabled(store.items.isEmpty)

            // 关闭按钮
            Button("Close") {
                onClose()
            }
            .keyboardShortcut(.cancelAction)
        }
    }

    // MARK: - 处理移动命令
    /// 处理键盘上下移动命令
    /// - Parameter direction: 移动方向
    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        switch direction {
        case .up:
            moveSelection(by: -1)
        case .down:
            moveSelection(by: 1)
        default:
            break
        }
    }

    // MARK: - 移动选择
    /// 按指定步长移动选中项
    /// - Parameter step: 移动步长（正数为向下，负数为向上）
    private func moveSelection(by step: Int) {
        guard !store.items.isEmpty else {
            selectedItemID = nil
            return
        }

        guard let selectedItemID,
              let currentIndex = store.items.firstIndex(where: { $0.id == selectedItemID }) else {
            // 如果没有选中项，选中第一项
            self.selectedItemID = store.items.first?.id
            return
        }

        // 计算新索引，确保在有效范围内
        let nextIndex = min(max(currentIndex + step, 0), store.items.count - 1)
        self.selectedItemID = store.items[nextIndex].id
    }

    // MARK: - 规范化选择
    /// 确保选中项始终有效
    /// 如果当前选中项被删除，则选中新第一项
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

    // MARK: - 选择当前项
    /// 触发选中项的回调
    private func selectCurrentItem() {
        guard let selectedItemID,
              let item = store.items.first(where: { $0.id == selectedItemID }) else {
            return
        }

        onSelect(item)
    }
}
