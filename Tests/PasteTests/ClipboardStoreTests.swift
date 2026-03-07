import XCTest
@testable import Paste

// MARK: - 剪贴板存储测试
/// 测试 ClipboardStore 的各项功能
@MainActor
final class ClipboardStoreTests: XCTestCase {
    // MARK: - 测试去重和数量限制
    /// 测试重复内容被去重，且列表数量不超过限制
    func testDeduplicateLatestAndTrimToLimit() {
        let storageURL = makeStorageURL()
        let store = ClipboardStore(maxItems: 3, storageURL: storageURL)

        // 添加 A（两次，应该去重）
        store.addFromPasteboard("A", sourceAppBundleId: nil)
        store.addFromPasteboard("A", sourceAppBundleId: nil)
        // 添加 B, C, D
        store.addFromPasteboard("B", sourceAppBundleId: nil)
        store.addFromPasteboard("C", sourceAppBundleId: nil)
        store.addFromPasteboard("D", sourceAppBundleId: nil)

        // 验证：最新的是 D，然后是 C，B（因为最大数量为3，A 被去重）
        XCTAssertEqual(store.items.map(\.content), ["D", "C", "B"])
    }

    // MARK: - 测试持久化往返
    /// 测试数据能够正确保存和加载
    func testPersistenceRoundTrip() {
        let storageURL = makeStorageURL()
        let firstStore = ClipboardStore(maxItems: 50, storageURL: storageURL)

        // 添加两条记录
        firstStore.addFromPasteboard("first", sourceAppBundleId: "com.example.one")
        firstStore.addFromPasteboard("second", sourceAppBundleId: "com.example.two")

        // 创建新实例并加载
        let secondStore = ClipboardStore(maxItems: 50, storageURL: storageURL)
        secondStore.load()

        // 验证数据正确
        XCTAssertEqual(secondStore.items.count, 2)
        XCTAssertEqual(secondStore.items[0].content, "second")
        XCTAssertEqual(secondStore.items[1].content, "first")
        XCTAssertEqual(secondStore.items[0].sourceAppBundleId, "com.example.two")
    }

    // MARK: - 测试无效 JSON 回退
    /// 测试当存储文件损坏时能正确回退到空状态
    func testInvalidJSONFallsBackToEmptyState() throws {
        let storageURL = makeStorageURL()
        // 写入无效的 JSON 数据
        try Data("not-json".utf8).write(to: storageURL, options: .atomic)

        let store = ClipboardStore(maxItems: 50, storageURL: storageURL)
        store.load()

        // 验证回退到空状态
        XCTAssertTrue(store.items.isEmpty)
    }

    // MARK: - 测试清除数据
    /// 测试清除功能能正确删除保存的数据
    func testClearResetsSavedData() {
        let storageURL = makeStorageURL()
        let store = ClipboardStore(maxItems: 50, storageURL: storageURL)

        // 添加一条记录
        store.addFromPasteboard("kept", sourceAppBundleId: nil)
        // 清除
        store.clear()

        // 重新加载
        let reloadedStore = ClipboardStore(maxItems: 50, storageURL: storageURL)
        reloadedStore.load()

        // 验证数据已清除
        XCTAssertTrue(reloadedStore.items.isEmpty)
    }

    // MARK: - 测试图片持久化
    /// 测试图片条目能够保存元数据并持久化
    func testImagePersistenceRoundTrip() {
        let storageURL = makeStorageURL()
        let firstStore = ClipboardStore(maxItems: 50, storageURL: storageURL)
        let imageData = Data([0x01, 0x02, 0x03, 0x04, 0x05])

        let image = ClipboardCapturedImage(
            data: imageData,
            pasteboardType: "public.png",
            pixelWidth: 320,
            pixelHeight: 180
        )
        firstStore.addFromPasteboard(.image(image), sourceAppBundleId: "com.example.image")

        XCTAssertEqual(firstStore.items.count, 1)
        guard let insertedItem = firstStore.items.first else {
            XCTFail("Missing inserted image item")
            return
        }
        XCTAssertNotNil(firstStore.imageAssetURL(for: insertedItem))

        let secondStore = ClipboardStore(maxItems: 50, storageURL: storageURL)
        secondStore.load()

        XCTAssertEqual(secondStore.items.count, 1)
        guard let reloadedItem = secondStore.items.first,
              let metadata = reloadedItem.imageMetadata else {
            XCTFail("Missing reloaded image metadata")
            return
        }
        XCTAssertEqual(metadata.pasteboardType, "public.png")
        XCTAssertEqual(metadata.byteSize, imageData.count)
        XCTAssertEqual(metadata.pixelWidth, 320)
        XCTAssertEqual(metadata.pixelHeight, 180)

        let blob = secondStore.imageBlob(for: reloadedItem)
        XCTAssertEqual(blob?.data, imageData)
        XCTAssertEqual(blob?.pasteboardType, "public.png")
    }

    // MARK: - 测试内容分类
    /// 测试文本和图片条目会被正确分类
    func testItemCategoryForTextAndImage() {
        let storageURL = makeStorageURL()
        let store = ClipboardStore(maxItems: 50, storageURL: storageURL)

        store.addFromPasteboard("hello", sourceAppBundleId: nil)
        let image = ClipboardCapturedImage(
            data: Data([0x01, 0x02, 0x03]),
            pasteboardType: "public.png",
            pixelWidth: 1,
            pixelHeight: 1
        )
        store.addFromPasteboard(.image(image), sourceAppBundleId: nil)

        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items[0].category, .image)
        XCTAssertEqual(store.items[1].category, .text)
        XCTAssertFalse(store.items[0].isFavorite)
        XCTAssertFalse(store.items[1].isFavorite)
    }

    // MARK: - 测试收藏切换与持久化
    /// 测试收藏状态可切换并正确持久化
    func testToggleFavoriteAndPersist() {
        let storageURL = makeStorageURL()
        let firstStore = ClipboardStore(maxItems: 50, storageURL: storageURL)
        firstStore.addFromPasteboard("favorite-me", sourceAppBundleId: nil)

        guard let itemID = firstStore.items.first?.id else {
            XCTFail("Missing inserted item")
            return
        }

        firstStore.toggleFavorite(for: itemID)
        XCTAssertEqual(firstStore.items.first?.isFavorite, true)

        let secondStore = ClipboardStore(maxItems: 50, storageURL: storageURL)
        secondStore.load()
        XCTAssertEqual(secondStore.items.first?.isFavorite, true)
    }

    // MARK: - 测试图片去重
    /// 测试连续复制同一张图片时会按最新项去重
    func testDeduplicateLatestImagePayload() {
        let storageURL = makeStorageURL()
        let store = ClipboardStore(maxItems: 50, storageURL: storageURL)
        let imageData = Data([0x10, 0x11, 0x12, 0x13])

        let image = ClipboardCapturedImage(
            data: imageData,
            pasteboardType: "public.png",
            pixelWidth: nil,
            pixelHeight: nil
        )

        store.addFromPasteboard(.image(image), sourceAppBundleId: nil)
        store.addFromPasteboard(.image(image), sourceAppBundleId: nil)

        XCTAssertEqual(store.items.count, 1)
        XCTAssertNotNil(store.items.first?.imageMetadata)
    }

    // MARK: - 测试图片体积限制
    /// 测试超出单图体积上限的图片会被忽略
    func testImageOverSizeLimitIsIgnored() {
        let storageURL = makeStorageURL()
        let store = ClipboardStore(maxItems: 50, maxImageBytes: 3, storageURL: storageURL)
        let imageData = Data([0x01, 0x02, 0x03, 0x04])

        let image = ClipboardCapturedImage(
            data: imageData,
            pasteboardType: "public.png",
            pixelWidth: nil,
            pixelHeight: nil
        )
        store.addFromPasteboard(.image(image), sourceAppBundleId: nil)

        XCTAssertTrue(store.items.isEmpty)
    }

    // MARK: - 测试裁剪时清理图片资产
    /// 测试当历史超过上限导致图片被淘汰时，图片文件会被同步删除
    func testTrimRemovesOldImageAssetFile() {
        let storageURL = makeStorageURL()
        let store = ClipboardStore(maxItems: 1, storageURL: storageURL)
        let imageData = Data([0x41, 0x42, 0x43, 0x44])

        let image = ClipboardCapturedImage(
            data: imageData,
            pasteboardType: "public.png",
            pixelWidth: 32,
            pixelHeight: 32
        )
        store.addFromPasteboard(.image(image), sourceAppBundleId: nil)

        guard let imageItem = store.items.first,
              let imageURL = store.imageAssetURL(for: imageItem) else {
            XCTFail("Missing saved image asset")
            return
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: imageURL.path))

        // 加入新文本后，旧图片会被 maxItems=1 淘汰
        store.addFromPasteboard("new text", sourceAppBundleId: nil)

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.textContent, "new text")
        XCTAssertFalse(FileManager.default.fileExists(atPath: imageURL.path))
    }

    // MARK: - 测试清空时清理图片资产
    /// 测试 clear() 会删除图片对应的资产文件
    func testClearRemovesImageAssetFile() {
        let storageURL = makeStorageURL()
        let store = ClipboardStore(maxItems: 10, storageURL: storageURL)
        let imageData = Data([0x55, 0x56, 0x57, 0x58])

        let image = ClipboardCapturedImage(
            data: imageData,
            pasteboardType: "public.png",
            pixelWidth: 10,
            pixelHeight: 10
        )
        store.addFromPasteboard(.image(image), sourceAppBundleId: nil)

        guard let imageItem = store.items.first,
              let imageURL = store.imageAssetURL(for: imageItem) else {
            XCTFail("Missing saved image asset")
            return
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: imageURL.path))
        store.clear()
        XCTAssertFalse(FileManager.default.fileExists(atPath: imageURL.path))
    }

    // MARK: - 测试删除单条记录
    /// 测试删除单条图片记录时会清理对应资产并保留其他记录
    func testRemoveSingleItemRemovesOnlyTargetAsset() {
        let storageURL = makeStorageURL()
        let store = ClipboardStore(maxItems: 10, storageURL: storageURL)

        let imageA = ClipboardCapturedImage(
            data: Data([0x11, 0x22, 0x33]),
            pasteboardType: "public.png",
            pixelWidth: 10,
            pixelHeight: 10
        )
        let imageB = ClipboardCapturedImage(
            data: Data([0x44, 0x55, 0x66]),
            pasteboardType: "public.png",
            pixelWidth: 20,
            pixelHeight: 20
        )

        store.addFromPasteboard(.image(imageA), sourceAppBundleId: nil)
        store.addFromPasteboard(.image(imageB), sourceAppBundleId: nil)

        XCTAssertEqual(store.items.count, 2)
        guard let targetItem = store.items.first,
              let keptItem = store.items.last,
              let targetURL = store.imageAssetURL(for: targetItem),
              let keptURL = store.imageAssetURL(for: keptItem) else {
            XCTFail("Missing inserted image assets")
            return
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: targetURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: keptURL.path))

        store.remove(itemID: targetItem.id)

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.id, keptItem.id)
        XCTAssertFalse(FileManager.default.fileExists(atPath: targetURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: keptURL.path))
    }

    // MARK: - 测试旧版 JSON 迁移
    /// 测试旧字段 content 能向后兼容解码为文本条目
    func testLegacyContentFieldCanBeLoaded() throws {
        let storageURL = makeStorageURL()
        let legacyJSON = """
        [
          {
            "id": "11111111-1111-1111-1111-111111111111",
            "content": "legacy text",
            "copiedAt": "2026-03-07T00:00:00Z",
            "sourceAppBundleId": "com.example.legacy"
          }
        ]
        """
        try Data(legacyJSON.utf8).write(to: storageURL, options: .atomic)

        let store = ClipboardStore(maxItems: 50, storageURL: storageURL)
        store.load()

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.textContent, "legacy text")
        XCTAssertEqual(store.items.first?.sourceAppBundleId, "com.example.legacy")
        XCTAssertEqual(store.items.first?.isFavorite, false)
    }

    // MARK: - 辅助方法
    /// 创建测试用的临时存储 URL
    private func makeStorageURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("paste-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("history.json")
    }
}
