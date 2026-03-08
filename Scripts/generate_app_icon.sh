#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ICON_DIR="$ROOT_DIR/Resources/Icons"
ICONSET_DIR="$ROOT_DIR/Resources/AppIcon.iconset"
ICNS_PATH="$ROOT_DIR/Resources/AppIcon.icns"

python3 "$ROOT_DIR/Scripts/generate_app_icon.py"
sips -s format png "$ICON_DIR/app-icon.pam" --out "$ICON_DIR/AppIcon-1024.png" >/dev/null

mkdir -p "$ICONSET_DIR"
while read -r name size; do
  sips -z "$size" "$size" "$ICON_DIR/AppIcon-1024.png" --out "$ICONSET_DIR/$name" >/dev/null
done <<'EOF'
icon_16x16.png 16
icon_16x16@2x.png 32
icon_32x32.png 32
icon_32x32@2x.png 64
icon_128x128.png 128
icon_128x128@2x.png 256
icon_256x256.png 256
icon_256x256@2x.png 512
icon_512x512.png 512
icon_512x512@2x.png 1024
EOF

python3 - "$ICONSET_DIR" "$ICNS_PATH" <<'PY'
from pathlib import Path
import struct
import sys

iconset = Path(sys.argv[1])
out = Path(sys.argv[2])

entries = [
    ("icp4", iconset / "icon_16x16.png"),
    ("icp5", iconset / "icon_32x32.png"),
    ("icp6", iconset / "icon_32x32@2x.png"),
    ("ic07", iconset / "icon_128x128.png"),
    ("ic08", iconset / "icon_256x256.png"),
    ("ic09", iconset / "icon_512x512.png"),
    ("ic10", iconset / "icon_512x512@2x.png"),
]

chunks = []
for code, path in entries:
    data = path.read_bytes()
    chunks.append(code.encode("ascii") + struct.pack(">I", len(data) + 8) + data)

body = b"".join(chunks)
out.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)
print(f"Wrote {out}")
PY

echo "Generated $ICNS_PATH"
