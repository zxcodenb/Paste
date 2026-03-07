import AppKit
import Foundation

// MARK: - 剪贴板写入协议
/// 定义将文本写入剪贴板的功能接口
protocol PasteboardWriting {
    /// 将指定文本写入剪贴板
    /// - Parameter text: 要写入的文本内容
    func writeText(_ text: String)
}

// MARK: - 系统剪贴板写入器
/// 使用系统 NSPasteboard 实现剪贴板写入功能
struct SystemPasteboardWriter: PasteboardWriting {
    /// 系统剪贴板实例
    private let pasteboard: NSPasteboard

    /// 初始化写入器
    /// - Parameter pasteboard: 剪贴板实例，默认为系统通用剪贴板
    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    /// 将文本写入剪贴板
    /// - Parameter text: 要写入的文本内容
    func writeText(_ text: String) {
        // 清空剪贴板现有内容
        pasteboard.clearContents()
        // 将文本写入剪贴板的字符串类型
        pasteboard.setString(text, forType: .string)
    }
}
