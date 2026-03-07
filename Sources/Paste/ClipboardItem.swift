import Foundation

// MARK: - 剪贴板项目模型
/// 表示一个剪贴板历史记录项目
/// 包含复制的内容、复制时间以及来源应用信息
struct ClipboardItem: Codable, Identifiable, Equatable {
    /// 唯一标识符
    let id: UUID
    /// 剪贴板文本内容
    let content: String
    /// 复制时间
    let copiedAt: Date
    /// 来源应用的 Bundle 标识符（可选）
    let sourceAppBundleId: String?

    /// 初始化剪贴板项目
    /// - Parameters:
    ///   - id: 唯一标识符，默认为新生成的 UUID
    ///   - content: 剪贴板文本内容
    ///   - copiedAt: 复制时间，默认为当前时间
    ///   - sourceAppBundleId: 来源应用的 Bundle 标识符
    init(
        id: UUID = UUID(),
        content: String,
        copiedAt: Date = Date(),
        sourceAppBundleId: String? = nil
    ) {
        self.id = id
        self.content = content
        self.copiedAt = copiedAt
        self.sourceAppBundleId = sourceAppBundleId
    }
}
