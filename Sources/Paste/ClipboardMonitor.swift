import AppKit
import Foundation

// MARK: - 剪贴板监控器
/// 监控系统剪贴板的变化
/// 当检测到新的文本或图片内容时触发回调
@MainActor
final class ClipboardMonitor {
    /// 复制回调类型
    /// - Parameters:
    ///   - payload: 复制内容（文本或图片）
    ///   - sourceAppBundleId: 来源应用的 Bundle 标识符
    typealias OnPayloadCopied = (_ payload: ClipboardCapturedPayload, _ sourceAppBundleId: String?) -> Void

    /// 复制回调
    var onPayloadCopied: OnPayloadCopied?

    /// 系统剪贴板实例
    private let pasteboard: NSPasteboard
    /// 轮询间隔时间（秒）
    private let pollInterval: TimeInterval
    /// 定时器
    private var timer: Timer?
    /// 上一次剪贴板变化计数
    private var lastChangeCount: Int
    /// 需要忽略的下一次变化计数
    private var ignoredChangeCount: Int?

    /// 初始化剪贴板监控器
    /// - Parameters:
    ///   - pasteboard: 剪贴板实例，默认为系统通用剪贴板
    ///   - pollInterval: 轮询间隔时间，默认为 0.35 秒
    init(
        pasteboard: NSPasteboard = .general,
        pollInterval: TimeInterval = 0.35
    ) {
        self.pasteboard = pasteboard
        // 确保最小轮询间隔为 0.2 秒
        self.pollInterval = max(0.2, pollInterval)
        self.lastChangeCount = pasteboard.changeCount
    }

    /// 开始监控剪贴板
    func start() {
        // 防止重复启动
        guard timer == nil else {
            return
        }

        // 重置变化计数
        lastChangeCount = pasteboard.changeCount

        // 创建定时器定期检查剪贴板
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollClipboard()
            }
        }
        self.timer = timer
        // 添加到主运行循环
        RunLoop.main.add(timer, forMode: .common)
    }

    /// 停止监控剪贴板
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// 忽略下一次剪贴板变化
    /// 用于在用户从历史记录中选择内容复制时，避免重复添加到历史
    func ignoreNextChange() {
        ignoredChangeCount = pasteboard.changeCount + 1
    }

    /// 轮询检查剪贴板
    private func pollClipboard() {
        let currentChangeCount = pasteboard.changeCount
        // 如果没有变化，直接返回
        guard currentChangeCount != lastChangeCount else {
            return
        }

        // 更新最后变化计数
        lastChangeCount = currentChangeCount

        // 如果是忽略的变化计数，跳过
        if ignoredChangeCount == currentChangeCount {
            ignoredChangeCount = nil
            return
        }

        // 优先检测剪贴板中的图片对象，失败再回退文本
        guard let payload = readPayloadFromPasteboard() else {
            return
        }

        // 获取当前前台应用的 Bundle 标识符
        let sourceAppBundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        // 触发回调
        onPayloadCopied?(payload, sourceAppBundleId)
    }

    private func readPayloadFromPasteboard() -> ClipboardCapturedPayload? {
        if let imagePayload = readImagePayload() {
            return imagePayload
        }

        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            return nil
        }
        return .text(text)
    }

    private func readImagePayload() -> ClipboardCapturedPayload? {
        let candidates: [NSPasteboard.PasteboardType] = [.png, .tiff]

        for type in candidates {
            guard let data = pasteboard.data(forType: type), !data.isEmpty else {
                continue
            }

            let bitmapRep = NSBitmapImageRep(data: data)
            let image = ClipboardCapturedImage(
                data: data,
                pasteboardType: type.rawValue,
                pixelWidth: bitmapRep?.pixelsWide,
                pixelHeight: bitmapRep?.pixelsHigh
            )
            return .image(image)
        }

        return nil
    }
}
