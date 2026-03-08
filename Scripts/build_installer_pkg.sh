#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/dist/Paste.app"
PKG_DIR="$ROOT_DIR/dist"
PKG_PATH="$PKG_DIR/Paste-installer.pkg"

if ! [ -d "$APP_PATH" ]; then
  "$ROOT_DIR/Scripts/package_app.sh" release
fi

mkdir -p "$PKG_DIR"
productbuild --component "$APP_PATH" /Applications "$PKG_PATH"
echo "Built installer: $PKG_PATH"
