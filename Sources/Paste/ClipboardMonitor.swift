import AppKit
import Foundation

@MainActor
final class ClipboardMonitor {
    typealias OnTextCopied = (_ text: String, _ sourceAppBundleId: String?) -> Void

    var onTextCopied: OnTextCopied?

    private let pasteboard: NSPasteboard
    private let pollInterval: TimeInterval
    private var timer: Timer?
    private var lastChangeCount: Int
    private var ignoredChangeCount: Int?

    init(
        pasteboard: NSPasteboard = .general,
        pollInterval: TimeInterval = 0.35
    ) {
        self.pasteboard = pasteboard
        self.pollInterval = max(0.2, pollInterval)
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else {
            return
        }

        lastChangeCount = pasteboard.changeCount

        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollClipboard()
            }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func ignoreNextChange() {
        ignoredChangeCount = pasteboard.changeCount + 1
    }

    private func pollClipboard() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else {
            return
        }

        lastChangeCount = currentChangeCount

        if ignoredChangeCount == currentChangeCount {
            ignoredChangeCount = nil
            return
        }

        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            return
        }

        let sourceAppBundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        onTextCopied?(text, sourceAppBundleId)
    }
}
