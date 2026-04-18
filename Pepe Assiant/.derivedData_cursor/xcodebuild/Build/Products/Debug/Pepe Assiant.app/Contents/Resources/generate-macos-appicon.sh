#!/usr/bin/env bash
set -euo pipefail

SOURCE_PNG="${1:-Pepe Assiant/Assets.xcassets/netos-icon.imageset/netos-icon.png}"
APPICONSET_DIR="${2:-Pepe Assiant/Assets.xcassets/AppIcon.appiconset}"

if [[ ! -f "$SOURCE_PNG" ]]; then
  echo "Source PNG not found: $SOURCE_PNG" >&2
  exit 1
fi

if [[ ! -d "$APPICONSET_DIR" ]]; then
  echo "AppIcon.appiconset folder not found: $APPICONSET_DIR" >&2
  exit 1
fi

make_icon() {
  local px="$1"
  local out="$2"
  /usr/bin/sips -s format png --resampleHeightWidth "$px" "$px" "$SOURCE_PNG" --out "$out" >/dev/null
}

make_icon 16   "$APPICONSET_DIR/icon_16x16.png"
make_icon 32   "$APPICONSET_DIR/icon_16x16@2x.png"
make_icon 32   "$APPICONSET_DIR/icon_32x32.png"
make_icon 64   "$APPICONSET_DIR/icon_32x32@2x.png"
make_icon 128  "$APPICONSET_DIR/icon_128x128.png"
make_icon 256  "$APPICONSET_DIR/icon_128x128@2x.png"
make_icon 256  "$APPICONSET_DIR/icon_256x256.png"
make_icon 512  "$APPICONSET_DIR/icon_256x256@2x.png"
make_icon 512  "$APPICONSET_DIR/icon_512x512.png"
make_icon 1024 "$APPICONSET_DIR/icon_512x512@2x.png"

echo "Generated macOS AppIcon PNGs in: $APPICONSET_DIR"
