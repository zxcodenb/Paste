import Carbon
import Foundation

// MARK: - 快捷键管理器
/// 管理全局快捷键的注册和响应
/// 使用 Option + Space 快捷键切换历史面板
@MainActor
final class HotkeyManager {
    /// 切换面板回调
    var onTogglePanel: (() -> Void)?

    /// 热键签名（四个字符代码）
    private static let hotkeySignature = fourCharCode("PSTE")

    /// 事件处理器引用
    private var eventHandlerRef: EventHandlerRef?
    /// 热键引用
    private var hotKeyRef: EventHotKeyRef?
    /// 是否已注册快捷键
    private var isRegistered = false

    /// 注册切换面板的快捷键
    /// 默认快捷键：Option + Space
    func registerTogglePanelHotkey() {
        guard !isRegistered else {
            return
        }

        // 定义事件类型规格
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // 创建用户数据指针
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        // 安装事件处理器
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else {
                    return OSStatus(eventNotHandledErr)
                }

                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    manager.handleHotkey()
                }
                return noErr
            },
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            return
        }

        // 注册热键：Option + Space
        let hotKeyID = EventHotKeyID(signature: Self.hotkeySignature, id: 1)
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr else {
            // 注册失败时移除事件处理器
            if let eventHandlerRef {
                RemoveEventHandler(eventHandlerRef)
                self.eventHandlerRef = nil
            }
            return
        }

        isRegistered = true
    }

    /// 注销快捷键
    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }

        isRegistered = false
    }

    /// 处理热键事件
    private func handleHotkey() {
        onTogglePanel?()
    }
}

// MARK: - 辅助函数
/// 将字符串转换为四个字符代码
/// - Parameter string: 输入字符串
/// - Returns: OSType 值
private func fourCharCode(_ string: String) -> OSType {
    var value: UInt32 = 0
    for character in string.utf8.prefix(4) {
        value = (value << 8) + UInt32(character)
    }
    return OSType(value)
}
