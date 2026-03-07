import AppKit
import Foundation
import SwiftUI

// MARK: - 应用控制器
/// 管理 Paste 应用的核心逻辑
/// 负责协调剪贴板监控、存储、快捷键和面板显示
@MainActor
final class AppController: ObservableObject {
    /// 剪贴板历史记录存储
    let store: ClipboardStore
    /// 开机启动管理器
    let launchAtLoginManager: LaunchAtLoginManager

    /// 剪贴板监控器
    private let clipboardMonitor: ClipboardMonitor
    /// 快捷键管理器
    private let hotkeyManager: HotkeyManager
    /// 剪贴板写入器
    private let pasteboardWriter: any PasteboardWriting
    /// 来源应用解析器
    private let sourceAppResolver: any SourceAppResolving
    /// 标记应用是否已启动
    private var didStart = false

    /// 面板控制器，用于显示历史记录面板
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
                },
                sourceAppResolver: self.sourceAppResolver
            )
        )
    }

    /// 初始化应用控制器
    /// - Parameters:
    ///   - store: 剪贴板存储实例
    ///   - launchAtLoginManager: 开机启动管理器
    ///   - clipboardMonitor: 剪贴板监控器
    ///   - hotkeyManager: 快捷键管理器
    ///   - pasteboardWriter: 剪贴板写入器
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
        self.sourceAppResolver = SourceAppResolver()

        // 设置剪贴板监控回调 - 当检测到新内容时添加到存储
        self.clipboardMonitor.onPayloadCopied = { [weak self] payload, sourceBundleId in
            self?.store.addFromPasteboard(payload, sourceAppBundleId: sourceBundleId)
        }

        // 设置快捷键回调 - 切换历史面板显示
        self.hotkeyManager.onTogglePanel = { [weak self] in
            self?.toggleHistoryPanel()
        }
    }

    /// 启动应用
    /// 加载历史记录，开始监控剪贴板，注册快捷键
    func start() {
        guard !didStart else {
            return
        }

        didStart = true
        store.load()
        clipboardMonitor.start()
        hotkeyManager.registerTogglePanelHotkey()
    }

    /// 停止应用
    /// 停止监控，注销快捷键，保存历史记录
    func stop() {
        clipboardMonitor.stop()
        hotkeyManager.unregister()
        store.save()
    }

    /// 打开历史面板
    func openHistoryPanel() {
        panelController.show()
    }

    /// 隐藏历史面板
    func hideHistoryPanel() {
        panelController.hide()
    }

    /// 切换历史面板显示状态
    func toggleHistoryPanel() {
        panelController.toggle()
    }

    /// 清除所有历史记录
    func clearHistory() {
        store.clear()
    }

    /// 处理选中项目
    /// 将选中的历史记录写入剪贴板并隐藏面板
    /// - Parameter item: 选中的剪贴板项目
    private func handleSelection(_ item: ClipboardItem) {
        // 忽略下一次剪贴板变化（避免重复添加刚复制的内容）
        clipboardMonitor.ignoreNextChange()
        // 将选中内容写入剪贴板
        switch item.payload {
        case let .text(text):
            pasteboardWriter.writeText(text)
        case .image:
            guard let blob = store.imageBlob(for: item) else {
                return
            }
            pasteboardWriter.writeImageData(blob.data, pasteboardType: blob.pasteboardType)
        }
        // 隐藏面板
        hideHistoryPanel()
    }
}
