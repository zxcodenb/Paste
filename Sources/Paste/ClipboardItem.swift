import Foundation

struct ClipboardItem: Codable, Identifiable, Equatable {
    let id: UUID
    let content: String
    let copiedAt: Date
    let sourceAppBundleId: String?

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
