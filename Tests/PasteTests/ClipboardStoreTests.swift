import XCTest
@testable import Paste

@MainActor
final class ClipboardStoreTests: XCTestCase {
    func testDeduplicateLatestAndTrimToLimit() {
        let storageURL = makeStorageURL()
        let store = ClipboardStore(maxItems: 3, storageURL: storageURL)

        store.addFromPasteboard("A", sourceAppBundleId: nil)
        store.addFromPasteboard("A", sourceAppBundleId: nil)
        store.addFromPasteboard("B", sourceAppBundleId: nil)
        store.addFromPasteboard("C", sourceAppBundleId: nil)
        store.addFromPasteboard("D", sourceAppBundleId: nil)

        XCTAssertEqual(store.items.map(\.content), ["D", "C", "B"])
    }

    func testPersistenceRoundTrip() {
        let storageURL = makeStorageURL()
        let firstStore = ClipboardStore(maxItems: 50, storageURL: storageURL)

        firstStore.addFromPasteboard("first", sourceAppBundleId: "com.example.one")
        firstStore.addFromPasteboard("second", sourceAppBundleId: "com.example.two")

        let secondStore = ClipboardStore(maxItems: 50, storageURL: storageURL)
        secondStore.load()

        XCTAssertEqual(secondStore.items.count, 2)
        XCTAssertEqual(secondStore.items[0].content, "second")
        XCTAssertEqual(secondStore.items[1].content, "first")
        XCTAssertEqual(secondStore.items[0].sourceAppBundleId, "com.example.two")
    }

    func testInvalidJSONFallsBackToEmptyState() throws {
        let storageURL = makeStorageURL()
        try Data("not-json".utf8).write(to: storageURL, options: .atomic)

        let store = ClipboardStore(maxItems: 50, storageURL: storageURL)
        store.load()

        XCTAssertTrue(store.items.isEmpty)
    }

    func testClearResetsSavedData() {
        let storageURL = makeStorageURL()
        let store = ClipboardStore(maxItems: 50, storageURL: storageURL)

        store.addFromPasteboard("kept", sourceAppBundleId: nil)
        store.clear()

        let reloadedStore = ClipboardStore(maxItems: 50, storageURL: storageURL)
        reloadedStore.load()

        XCTAssertTrue(reloadedStore.items.isEmpty)
    }

    private func makeStorageURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("paste-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("history.json")
    }
}
