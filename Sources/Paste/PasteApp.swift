import AppKit
import SwiftUI

// MARK: - Paste 应用入口
// 这是一个 macOS 菜单栏应用，用于管理剪贴板历史记录
@main
@MainActor
struct PasteApp: App {
    // 应用控制器，负责管理整个应用的生命周期和状态
    @StateObject private var controller: AppController

    init() {
        // 将应用设置为辅助应用模式（菜单栏应用，不显示 Dock 图标）
        NSApplication.shared.setActivationPolicy(.accessory)
        let appController = AppController()
        _controller = StateObject(wrappedValue: appController)
        // 启动应用控制器，开始监控剪贴板
        appController.start()
    }

    var body: some Scene {
        // 菜单栏菜单项
        MenuBarExtra("Paste", systemImage: "doc.on.clipboard") {
            MenuBarContentView(
                store: controller.store,
                launchAtLoginManager: controller.launchAtLoginManager,
                onOpenHistory: controller.openHistoryPanel,
                onClearHistory: controller.clearHistory
            )
        }
        .menuBarExtraStyle(.menu)

        // 设置窗口
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
