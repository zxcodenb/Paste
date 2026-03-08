#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/dist/Paste.app"
DMG_DIR="$ROOT_DIR/dist"
DMG_PATH="$DMG_DIR/Paste.dmg"

if ! [ -d "$APP_PATH" ]; then
  "$ROOT_DIR/Scripts/package_app.sh" release
fi

mkdir -p "$DMG_DIR"

# 移除旧的 DMG（如果存在）
rm -f "$DMG_PATH"

hdiutil create \
  -volname "Paste" \
  -srcfolder "$APP_PATH" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Built DMG: $DMG_PATH"
