import AppKit
import SwiftUI

// MARK: - 菜单栏内容视图
/// 菜单栏下拉菜单的内容视图
/// 提供打开历史、清除历史、设置等操作
struct MenuBarContentView: View {
    /// 剪贴板存储
    @ObservedObject var store: ClipboardStore
    /// 开机启动管理器
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager

    /// 打开历史面板回调
    let onOpenHistory: () -> Void
    /// 打开设置面板回调
    let onOpenSettings: () -> Void
    /// 清除历史回调
    let onClearHistory: () -> Void

    var body: some View {
        // 打开历史记录按钮
        Button("Open History") {
            onOpenHistory()
        }

        // 清除历史按钮
        Button("Clear History") {
            onClearHistory()
        }
        .disabled(store.items.isEmpty)

        Divider()

        // 开机启动开关
        Toggle("Launch at Login", isOn: Binding(
            get: { launchAtLoginManager.isEnabled },
            set: { launchAtLoginManager.setEnabled($0) }
        ))

        Divider()

        // 设置按钮
        Button("Settings") {
            onOpenSettings()
        }

        // 退出按钮
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
