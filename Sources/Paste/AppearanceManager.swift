import SwiftUI

// MARK: - 外观管理器
/// 管理应用外观模式（浅色/深色/跟随系统）
@MainActor
final class AppearanceManager: ObservableObject {
    /// 外观模式
    enum Mode: String, CaseIterable {
        case light
        case dark
        case auto

        var label: String {
            switch self {
            case .light: return "浅色"
            case .dark: return "深色"
            case .auto: return "跟随系统"
            }
        }
    }

    /// 用户选择的外观模式，持久化到 UserDefaults
    @AppStorage("appearanceMode") var mode: Mode = .auto

    /// 解析为 SwiftUI ColorScheme
    /// light → .light, dark → .dark, auto → nil（跟随系统）
    var resolvedColorScheme: ColorScheme? {
        switch mode {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
        }
    }
}
