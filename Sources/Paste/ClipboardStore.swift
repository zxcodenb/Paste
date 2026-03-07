import Combine
import Foundation

@MainActor
protocol ClipboardStoreProtocol: AnyObject {
    var items: [ClipboardItem] { get }
    func addFromPasteboard(_ text: String, sourceAppBundleId: String?)
    func clear()
    func load()
    func save()
}

@MainActor
final class ClipboardStore: ObservableObject, ClipboardStoreProtocol {
    @Published private(set) var items: [ClipboardItem] = []

    let maxItems: Int

    private let storageURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

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
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func addFromPasteboard(_ text: String, sourceAppBundleId: String?) {
        guard !text.isEmpty else {
            return
        }

        if let latest = items.first, latest.content == text {
            return
        }

        let item = ClipboardItem(content: text, sourceAppBundleId: sourceAppBundleId)
        items.insert(item, at: 0)

        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    func load() {
        guard fileManager.fileExists(atPath: storageURL.path) else {
            items = []
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let decodedItems = try decoder.decode([ClipboardItem].self, from: data)
            items = Array(decodedItems.prefix(maxItems))
        } catch {
            items = []
        }
    }

    func save() {
        let parentDirectory = storageURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
            let data = try encoder.encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            // Keep failures non-fatal in local utility context.
        }
    }

    private static func defaultStorageURL(fileManager: FileManager) -> URL {
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return appSupportDirectory
            .appendingPathComponent("Paste", isDirectory: true)
            .appendingPathComponent("clipboard-history.json")
    }
}
