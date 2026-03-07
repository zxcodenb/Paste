import Combine
import Foundation
import ServiceManagement

// MARK: - 开机启动管理器
/// 管理应用开机启动的注册和注销
/// 使用 ServiceManagement 框架实现
@MainActor
final class LaunchAtLoginManager: ObservableObject {
    /// 当前是否已启用开机启动
    @Published private(set) var isEnabled = false
    /// 错误信息（如果有）
    @Published private(set) var errorMessage: String?

    init() {
        reloadStatus()
    }

    /// 重新加载当前启动状态
    func reloadStatus() {
        switch SMAppService.mainApp.status {
        case .enabled:
            isEnabled = true
        default:
            isEnabled = false
        }
    }

    /// 设置开机启动状态
    /// - Parameter enabled: 是否启用开机启动
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                // 注册开机启动
                try SMAppService.mainApp.register()
            } else {
                // 注销开机启动
                try SMAppService.mainApp.unregister()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        reloadStatus()
    }
}
