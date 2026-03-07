import AppKit
import Foundation

protocol PasteboardWriting {
    func writeText(_ text: String)
}

struct SystemPasteboardWriter: PasteboardWriting {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func writeText(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
