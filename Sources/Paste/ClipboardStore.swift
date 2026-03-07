import Combine
import CryptoKit
import Foundation

// MARK: - 剪贴板存储协议
/// 定义剪贴板存储的核心功能接口
@MainActor
protocol ClipboardStoreProtocol: AnyObject {
    /// 当前存储的所有剪贴板项目
    var items: [ClipboardItem] { get }
    /// 从剪贴板添加新项目（文本或图片）
    /// - Parameters:
    ///   - payload: 剪贴板捕获内容
    ///   - sourceAppBundleId: 来源应用的 Bundle 标识符
    func addFromPasteboard(_ payload: ClipboardCapturedPayload, sourceAppBundleId: String?)
    /// 清空所有历史记录
    func clear()
    /// 从磁盘加载历史记录
    func load()
    /// 将历史记录保存到磁盘
    func save()
    /// 切换某条记录的收藏状态
    /// - Parameter itemID: 历史记录 ID
    func toggleFavorite(for itemID: ClipboardItem.ID)
    /// 删除某条历史记录
    /// - Parameter itemID: 历史记录 ID
    func remove(itemID: ClipboardItem.ID)
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
    /// 单张图片允许的最大字节数
    let maxImageBytes: Int

    /// 存储文件的 URL
    private let storageURL: URL
    /// 图片资产目录 URL
    private let assetsDirectoryURL: URL
    /// 文件管理器
    private let fileManager: FileManager
    /// JSON 编码器
    private let encoder: JSONEncoder
    /// JSON 解码器
    private let decoder: JSONDecoder

    /// 初始化剪贴板存储
    /// - Parameters:
    ///   - maxItems: 最大保存的项目数量，默认为 50
    ///   - maxImageBytes: 单张图片最大体积，默认为 10 MB
    ///   - storageURL: 存储文件的 URL，默认为默认位置
    ///   - fileManager: 文件管理器，默认为默认实例
    init(
        maxItems: Int = 50,
        maxImageBytes: Int = 10 * 1024 * 1024,
        storageURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.maxItems = max(1, maxItems)
        self.maxImageBytes = max(1, maxImageBytes)
        self.fileManager = fileManager
        self.storageURL = storageURL ?? Self.defaultStorageURL(fileManager: fileManager)
        self.assetsDirectoryURL = self.storageURL.deletingLastPathComponent().appendingPathComponent("assets", isDirectory: true)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        // 使用 ISO8601 日期格式
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    /// 向后兼容调用入口：添加文本
    /// - Parameters:
    ///   - text: 文本内容
    ///   - sourceAppBundleId: 来源应用
    /// 从剪贴板添加新项目
    func addFromPasteboard(_ text: String, sourceAppBundleId: String?) {
        addFromPasteboard(.text(text), sourceAppBundleId: sourceAppBundleId)
    }

    /// 从剪贴板添加新项目
    /// - Parameters:
    ///   - payload: 剪贴板捕获内容（文本或图片）
    ///   - sourceAppBundleId: 来源应用的 Bundle 标识符
    func addFromPasteboard(_ payload: ClipboardCapturedPayload, sourceAppBundleId: String?) {
        let item: ClipboardItem

        switch payload {
        case let .text(text):
            guard !text.isEmpty else {
                return
            }

            if let latest = items.first,
               latest.textContent == text {
                return
            }

            item = ClipboardItem(payload: .text(text), sourceAppBundleId: sourceAppBundleId)

        case let .image(image):
            guard image.byteSize > 0, image.byteSize <= maxImageBytes else {
                return
            }

            let digest = Self.sha256Hex(of: image.data)
            if let latest = items.first?.imageMetadata,
               latest.sha256 == digest {
                return
            }

            do {
                try ensureAssetsDirectory()
                let fileName = imageFileName(for: image.pasteboardType)
                let fileURL = assetsDirectoryURL.appendingPathComponent(fileName)
                try image.data.write(to: fileURL, options: .atomic)

                let metadata = ClipboardItem.ImageMetadata(
                    assetFileName: fileName,
                    pasteboardType: image.pasteboardType,
                    byteSize: image.byteSize,
                    pixelWidth: image.pixelWidth,
                    pixelHeight: image.pixelHeight,
                    sha256: digest
                )
                item = ClipboardItem(payload: .image(metadata), sourceAppBundleId: sourceAppBundleId)
            } catch {
                return
            }
        }

        items.insert(item, at: 0)
        trimToLimitAndCleanAssets()
        save()
    }

    /// 获取图片条目的二进制数据
    /// - Parameter item: 历史记录条目
    /// - Returns: 图片数据与类型；非图片或读取失败时返回 nil
    func imageBlob(for item: ClipboardItem) -> ClipboardImageBlob? {
        guard let metadata = item.imageMetadata else {
            return nil
        }
        let fileURL = assetsDirectoryURL.appendingPathComponent(metadata.assetFileName)
        guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else {
            return nil
        }
        return ClipboardImageBlob(data: data, pasteboardType: metadata.pasteboardType)
    }

    /// 获取图片资产 URL（用于 UI 缩略图读取）
    /// - Parameter item: 历史记录条目
    /// - Returns: 图片资产 URL
    func imageAssetURL(for item: ClipboardItem) -> URL? {
        guard let metadata = item.imageMetadata else {
            return nil
        }
        return assetsDirectoryURL.appendingPathComponent(metadata.assetFileName)
    }

    /// 切换某条记录的收藏状态
    /// - Parameter itemID: 历史记录 ID
    func toggleFavorite(for itemID: ClipboardItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else {
            return
        }

        items[index].isFavorite.toggle()
        save()
    }

    /// 删除某条历史记录
    /// - Parameter itemID: 历史记录 ID
    func remove(itemID: ClipboardItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else {
            return
        }

        let removedItem = items.remove(at: index)
        removeAssets(for: [removedItem])
        save()
    }

    /// 清空所有历史记录
    func clear() {
        let previousItems = items
        items.removeAll()
        removeAssets(for: previousItems)
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
            let removedItemsByLimit = Array(decodedItems.dropFirst(maxItems))
            removeAssets(for: removedItemsByLimit)

            let trimmedItems = Array(decodedItems.prefix(maxItems))
            items = trimmedItems.filter { item in
                guard let metadata = item.imageMetadata else {
                    return true
                }
                let fileURL = assetsDirectoryURL.appendingPathComponent(metadata.assetFileName)
                return fileManager.fileExists(atPath: fileURL.path)
            }

            if !removedItemsByLimit.isEmpty || items.count != trimmedItems.count {
                save()
            }
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
            try ensureAssetsDirectory()
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

    private func trimToLimitAndCleanAssets() {
        guard items.count > maxItems else {
            return
        }

        let removedItems = Array(items.dropFirst(maxItems))
        items = Array(items.prefix(maxItems))
        removeAssets(for: removedItems)
    }

    private func removeAssets(for removedItems: [ClipboardItem]) {
        for item in removedItems {
            guard let metadata = item.imageMetadata else {
                continue
            }
            let fileURL = assetsDirectoryURL.appendingPathComponent(metadata.assetFileName)
            try? fileManager.removeItem(at: fileURL)
        }
    }

    private func ensureAssetsDirectory() throws {
        try fileManager.createDirectory(at: assetsDirectoryURL, withIntermediateDirectories: true)
    }

    private func imageFileName(for pasteboardType: String) -> String {
        let fileExtension: String
        switch pasteboardType {
        case "public.png":
            fileExtension = "png"
        case "public.tiff":
            fileExtension = "tiff"
        default:
            fileExtension = "img"
        }

        return "\(UUID().uuidString).\(fileExtension)"
    }

    private static func sha256Hex(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
