剪切板历史工具

## 设置 App 包图标并打包

```bash
./Scripts/generate_app_icon.sh
./Scripts/package_app.sh release
```

产物路径：

```text
dist/Paste.app
```

`Paste.app` 的 Finder 图标来自 `Resources/AppIcon.icns`，`Info.plist` 位于 `Packaging/Info.plist`。

## 本机正式安装

1. 打包并签名（默认 ad-hoc）：

```bash
./Scripts/package_app.sh release
```

2. 安装到应用程序目录：

```bash
cp -R dist/Paste.app /Applications/
```

3. 首次运行（如果被系统拦截）：

```bash
xattr -dr com.apple.quarantine /Applications/Paste.app
open /Applications/Paste.app
```

## 生成安装包（pkg）

```bash
./Scripts/build_installer_pkg.sh
```

产物：

```text
dist/Paste-installer.pkg
```
