import Foundation

// MARK: - 剪贴板项目模型
/// 表示一个剪贴板历史记录项目
/// 包含复制的内容、复制时间以及来源应用信息
struct ClipboardItem: Codable, Identifiable, Equatable {
    enum Category: String, Codable {
        case text
        case image
    }

    struct ImageMetadata: Codable, Equatable {
        /// 图片资产文件名（存储在 assets 目录）
        let assetFileName: String
        /// 剪贴板类型（如 public.png / public.tiff）
        let pasteboardType: String
        /// 图片二进制大小（字节）
        let byteSize: Int
        /// 图片像素宽度
        let pixelWidth: Int?
        /// 图片像素高度
        let pixelHeight: Int?
        /// 图片内容哈希，用于去重
        let sha256: String
    }

    enum Payload: Equatable {
        case text(String)
        case image(ImageMetadata)
    }

    private enum PayloadKind: String, Codable {
        case text
        case image
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case payloadKind
        case text
        case image
        case copiedAt
        case sourceAppBundleId
        case isFavorite
        // 旧版本字段，仅用于向后兼容
        case content
    }

    /// 唯一标识符
    let id: UUID
    /// 剪贴板载荷
    let payload: Payload
    /// 复制时间
    let copiedAt: Date
    /// 来源应用的 Bundle 标识符（可选）
    let sourceAppBundleId: String?
    /// 是否已收藏
    var isFavorite: Bool

    /// 文本内容（仅文本条目）
    var textContent: String? {
        guard case let .text(value) = payload else {
            return nil
        }
        return value
    }

    /// 图片元数据（仅图片条目）
    var imageMetadata: ImageMetadata? {
        guard case let .image(metadata) = payload else {
            return nil
        }
        return metadata
    }

    /// 复制内容分类
    var category: Category {
        switch payload {
        case .text:
            return .text
        case .image:
            return .image
        }
    }

    /// 兼容旧调用方使用的展示内容
    var content: String {
        if let textContent {
            return textContent
        }

        return "[Image]"
    }

    /// 初始化剪贴板项目
    /// - Parameters:
    ///   - id: 唯一标识符，默认为新生成的 UUID
    ///   - payload: 剪贴板内容载荷
    ///   - copiedAt: 复制时间，默认为当前时间
    ///   - sourceAppBundleId: 来源应用的 Bundle 标识符
    ///   - isFavorite: 是否已收藏
    init(
        id: UUID = UUID(),
        payload: Payload,
        copiedAt: Date = Date(),
        sourceAppBundleId: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.payload = payload
        self.copiedAt = copiedAt
        self.sourceAppBundleId = sourceAppBundleId
        self.isFavorite = isFavorite
    }

    /// 向后兼容的文本初始化器
    init(
        id: UUID = UUID(),
        content: String,
        copiedAt: Date = Date(),
        sourceAppBundleId: String? = nil,
        isFavorite: Bool = false
    ) {
        self.init(
            id: id,
            payload: .text(content),
            copiedAt: copiedAt,
            sourceAppBundleId: sourceAppBundleId,
            isFavorite: isFavorite
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        copiedAt = try container.decodeIfPresent(Date.self, forKey: .copiedAt) ?? Date()
        sourceAppBundleId = try container.decodeIfPresent(String.self, forKey: .sourceAppBundleId)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false

        if let payloadKind = try container.decodeIfPresent(PayloadKind.self, forKey: .payloadKind) {
            switch payloadKind {
            case .text:
                if let text = try container.decodeIfPresent(String.self, forKey: .text) {
                    payload = .text(text)
                    return
                }

                if let legacyContent = try container.decodeIfPresent(String.self, forKey: .content) {
                    payload = .text(legacyContent)
                    return
                }

                throw DecodingError.dataCorruptedError(
                    forKey: .text,
                    in: container,
                    debugDescription: "Missing text payload."
                )
            case .image:
                let metadata = try container.decode(ImageMetadata.self, forKey: .image)
                payload = .image(metadata)
                return
            }
        }

        if let legacyContent = try container.decodeIfPresent(String.self, forKey: .content) {
            payload = .text(legacyContent)
            return
        }

        if let text = try container.decodeIfPresent(String.self, forKey: .text) {
            payload = .text(text)
            return
        }

        throw DecodingError.dataCorruptedError(
            forKey: .payloadKind,
            in: container,
            debugDescription: "Unsupported clipboard item payload."
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(copiedAt, forKey: .copiedAt)
        try container.encodeIfPresent(sourceAppBundleId, forKey: .sourceAppBundleId)
        try container.encode(isFavorite, forKey: .isFavorite)

        switch payload {
        case let .text(text):
            try container.encode(PayloadKind.text, forKey: .payloadKind)
            try container.encode(text, forKey: .text)
        case let .image(metadata):
            try container.encode(PayloadKind.image, forKey: .payloadKind)
            try container.encode(metadata, forKey: .image)
        }
    }
}
