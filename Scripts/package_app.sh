#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Paste"
BUILD_CONFIG="${1:-release}"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
MODULE_CACHE_DIR="$ROOT_DIR/.build/ModuleCache"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

if ! [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
  "$ROOT_DIR/Scripts/generate_app_icon.sh"
fi

mkdir -p "$MODULE_CACHE_DIR"
export SWIFT_MODULECACHE_PATH="$MODULE_CACHE_DIR"
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR"

BIN_DIR="$(cd "$ROOT_DIR" && swift build -c "$BUILD_CONFIG" --show-bin-path)"
BIN_PATH="$BIN_DIR/$APP_NAME"

if ! [ -x "$BIN_PATH" ]; then
  (cd "$ROOT_DIR" && swift build -c "$BUILD_CONFIG" --product "$APP_NAME")
fi

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$ROOT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"
codesign --force --deep --sign "$CODESIGN_IDENTITY" "$APP_DIR"
touch "$APP_DIR"

echo "Built and signed $APP_DIR"
