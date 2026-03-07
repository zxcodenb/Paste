import Foundation

/// 监控器从系统剪贴板捕获到的内容
enum ClipboardCapturedPayload: Equatable {
    case text(String)
    case image(ClipboardCapturedImage)
}

/// 捕获到的图片数据
struct ClipboardCapturedImage: Equatable {
    /// 原始图片数据
    let data: Data
    /// 原始剪贴板类型（如 public.png / public.tiff）
    let pasteboardType: String
    /// 图片像素宽度
    let pixelWidth: Int?
    /// 图片像素高度
    let pixelHeight: Int?

    var byteSize: Int {
        data.count
    }
}

/// 存储层返回给写回服务的图片数据
struct ClipboardImageBlob {
    let data: Data
    let pasteboardType: String
}
