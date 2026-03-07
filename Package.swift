// swift-tools-version: 6.2
// swift-tools-version 声明构建此包所需的最低 Swift 版本

import PackageDescription

// 包配置
let package = Package(
    // 包名称
    name: "Paste",
    // 支持的平台版本
    platforms: [
        .macOS(.v14),
    ],
    // 目标
    targets: [
        // 可执行目标 - 主应用
        .executableTarget(
            name: "Paste"
        ),
        // 测试目标
        .testTarget(
            name: "PasteTests",
            dependencies: ["Paste"]
        ),
    ]
)
