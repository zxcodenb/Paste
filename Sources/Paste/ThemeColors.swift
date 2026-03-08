import SwiftUI

// MARK: - 主题颜色
/// 根据当前色彩方案返回自适应颜色
enum ThemeColors {
    // MARK: - 背景渐变

    static func backgroundGradientStart(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.11, green: 0.11, blue: 0.14)
            : Color(red: 0.94, green: 0.96, blue: 1.0)
    }

    static func backgroundGradientEnd(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.09, green: 0.09, blue: 0.12)
            : Color(red: 0.91, green: 0.94, blue: 0.98)
    }

    // MARK: - 卡片

    static func cardFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.72)
    }

    static func cardBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.12)
            : Color.white.opacity(0.85)
    }

    // MARK: - 行

    static func rowFill(selected: Bool, _ scheme: ColorScheme) -> Color {
        if selected {
            return scheme == .dark
                ? Color.white.opacity(0.12)
                : Color.white.opacity(0.55)
        } else {
            return scheme == .dark
                ? Color.white.opacity(0.05)
                : Color.white.opacity(0.35)
        }
    }

    static func rowBorder(selected: Bool, _ scheme: ColorScheme) -> Color {
        if selected {
            return scheme == .dark
                ? Color.white.opacity(0.15)
                : Color.white.opacity(0.8)
        } else {
            return scheme == .dark
                ? Color.white.opacity(0.08)
                : Color.white.opacity(0.45)
        }
    }

    // MARK: - 按钮

    static func buttonFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.1)
            : Color.white.opacity(0.55)
    }

    static func buttonFillSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.1)
            : Color.white.opacity(0.5)
    }

    // MARK: - 阴影

    static func shadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.black.opacity(0.3)
            : Color.black.opacity(0.06)
    }

    static func shadowSelected(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.black.opacity(0.4)
            : Color.black.opacity(0.07)
    }

    static func shadowUnselected(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.black.opacity(0.2)
            : Color.black.opacity(0.02)
    }

    // MARK: - 顶部高光

    static func topHighlight(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.35)
    }

    // MARK: - 标签/空状态

    static func tagFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.1)
            : Color.white.opacity(0.55)
    }

    static func tagBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.12)
            : Color.white.opacity(0.7)
    }

    static func emptyStateFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.06)
            : Color.white.opacity(0.45)
    }

    static func emptyStateBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.1)
            : Color.white.opacity(0.6)
    }
}
