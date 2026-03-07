import SwiftUI

// MARK: - 设置视图
/// 应用设置界面
/// 显示通用设置和历史记录相关配置
struct SettingsView: View {
    /// 剪贴板存储
    @ObservedObject var store: ClipboardStore
    /// 开机启动管理器
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager
    /// 历史记录最大数量
    let historyLimit: Int
    /// 清除历史回调
    let onClearHistory: () -> Void

    var body: some View {
        Form {
            // 通用设置
            Section("General") {
                // 开机启动开关
                Toggle("Launch at Login", isOn: Binding(
                    get: { launchAtLoginManager.isEnabled },
                    set: { launchAtLoginManager.setEnabled($0) }
                ))

                // 快捷键显示
                HStack {
                    Text("Hotkey")
                    Spacer()
                    Text("Option + Space")
                        .foregroundStyle(.secondary)
                }
            }

            // 历史记录设置
            Section("History") {
                // 当前项目数量
                HStack {
                    Text("Current Items")
                    Spacer()
                    Text("\(store.items.count)")
                        .foregroundStyle(.secondary)
                }

                // 最大项目数量
                HStack {
                    Text("Max Items")
                    Spacer()
                    Text("\(historyLimit)")
                        .foregroundStyle(.secondary)
                }

                // 清除历史按钮
                Button("Clear History", role: .destructive) {
                    onClearHistory()
                }
                .disabled(store.items.isEmpty)
            }

            // 错误信息显示
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
