import AppKit
import SwiftUI

// MARK: - 面板控制器
/// 管理历史记录面板的显示和隐藏
/// 使用浮动面板实现
@MainActor
final class PanelController {
    /// 创建根视图的闭包
    private let makeRootView: () -> AnyView
    /// 浮动面板实例
    private var panel: NSPanel?

    /// 初始化面板控制器
    /// - Parameter makeRootView: 创建 SwiftUI 视图的闭包
    init(makeRootView: @escaping () -> AnyView) {
        self.makeRootView = makeRootView
    }

    /// 面板是否可见
    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    /// 切换面板显示状态
    func toggle() {
        isVisible ? hide() : show()
    }

    /// 显示面板
    func show() {
        let panel = ensurePanel()
        // 设置面板内容
        panel.contentView = NSHostingView(rootView: makeRootView())
        // 设置面板位置
        position(panel: panel)
        // 激活应用
        NSApplication.shared.activate(ignoringOtherApps: true)
        // 显示并置前
        panel.makeKeyAndOrderFront(nil)
    }

    /// 隐藏面板
    func hide() {
        panel?.orderOut(nil)
    }

    /// 确保面板已创建
    /// - Returns: 面板实例
    private func ensurePanel() -> NSPanel {
        if let panel {
            return panel
        }

        // 创建浮动面板
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // 配置面板属性
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        // 允许面板在所有空间和全屏辅助应用中使用
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        // 隐藏标题栏
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        // 关闭时释放内存
        panel.isReleasedWhenClosed = false
        // 隐藏最小化和缩放按钮
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        self.panel = panel
        return panel
    }

    /// 设置面板位置
    /// 面板显示在屏幕顶部中央
    /// - Parameter panel: 要定位的面板
    private func position(panel: NSPanel) {
        // 获取当前屏幕
        let screen = NSApplication.shared.keyWindow?.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else {
            return
        }

        let visibleFrame = screen.visibleFrame
        let width = panel.frame.width
        let height = panel.frame.height
        // 计算居中位置，Y 轴偏移到顶部
        let x = visibleFrame.midX - (width / 2)
        let y = visibleFrame.maxY - height - 80
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
