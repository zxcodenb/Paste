import Combine
import Foundation

// MARK: - 剪贴板存储协议
/// 定义剪贴板存储的核心功能接口
@MainActor
protocol ClipboardStoreProtocol: AnyObject {
    /// 当前存储的所有剪贴板项目
    var items: [ClipboardItem] { get }
    /// 从剪贴板添加新项目
    /// - Parameters:
    ///   - text: 文本内容
    ///   - sourceAppBundleId: 来源应用的 Bundle 标识符
    func addFromPasteboard(_ text: String, sourceAppBundleId: String?)
    /// 清空所有历史记录
    func clear()
    /// 从磁盘加载历史记录
    func load()
    /// 将历史记录保存到磁盘
    func save()
}

// MARK: - 剪贴板存储
/// 负责存储和管理剪贴板历史记录
/// 支持持久化存储到磁盘
@MainActor
final class ClipboardStore: ObservableObject, ClipboardStoreProtocol {
    /// 当前存储的所有剪贴板项目
    @Published private(set) var items: [ClipboardItem] = []

    /// 最大保存的项目数量
    let maxItems: Int

    /// 存储文件的 URL
    private let storageURL: URL
    /// 文件管理器
    private let fileManager: FileManager
    /// JSON 编码器
    private let encoder: JSONEncoder
    /// JSON 解码器
    private let decoder: JSONDecoder

    /// 初始化剪贴板存储
    /// - Parameters:
    ///   - maxItems: 最大保存的项目数量，默认为 50
    ///   - storageURL: 存储文件的 URL，默认为默认位置
    ///   - fileManager: 文件管理器，默认为默认实例
    init(
        maxItems: Int = 50,
        storageURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.maxItems = max(1, maxItems)
        self.fileManager = fileManager
        self.storageURL = storageURL ?? Self.defaultStorageURL(fileManager: fileManager)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        // 使用 ISO8601 日期格式
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    /// 从剪贴板添加新项目
    /// - Parameters:
    ///   - text: 文本内容
    ///   - sourceAppBundleId: 来源应用的 Bundle 标识符
    func addFromPasteboard(_ text: String, sourceAppBundleId: String?) {
        // 忽略空文本
        guard !text.isEmpty else {
            return
        }

        // 忽略重复内容（与最新项目相同）
        if let latest = items.first, latest.content == text {
            return
        }

        // 创建新项目并插入到列表开头
        let item = ClipboardItem(content: text, sourceAppBundleId: sourceAppBundleId)
        items.insert(item, at: 0)

        // 如果超过最大数量，截断列表
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        // 保存到磁盘
        save()
    }

    /// 清空所有历史记录
    func clear() {
        items.removeAll()
        save()
    }

    /// 从磁盘加载历史记录
    func load() {
        // 检查文件是否存在
        guard fileManager.fileExists(atPath: storageURL.path) else {
            items = []
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let decodedItems = try decoder.decode([ClipboardItem].self, from: data)
            items = Array(decodedItems.prefix(maxItems))
        } catch {
            // 加载失败时重置为空列表
            items = []
        }
    }

    /// 将历史记录保存到磁盘
    func save() {
        let parentDirectory = storageURL.deletingLastPathComponent()

        do {
            // 创建必要的目录
            try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
            // 编码并写入文件
            let data = try encoder.encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            // 本地工具应用中保持失败非致命
        }
    }

    /// 获取默认存储位置
    /// - Parameter fileManager: 文件管理器
    /// - Returns: 存储文件的 URL
    private static func defaultStorageURL(fileManager: FileManager) -> URL {
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return appSupportDirectory
            .appendingPathComponent("Paste", isDirectory: true)
            .appendingPathComponent("clipboard-history.json")
    }
}
