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

    // MARK: - 辅助方法
    /// 创建测试用的临时存储 URL
    private func makeStorageURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("paste-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("history.json")
    }
}
