#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="${1:?usage: make-appimage.sh <bundle-dir> <output-appimage> <version>}"
OUT="${2:?}"
VERSION="${3:?}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

APPDIR="$WORK/AppDir"
mkdir -p "$APPDIR"
cp -a "$BUNDLE_DIR/." "$APPDIR/"

install -m755 "$SCRIPT_DIR/AppRun" "$APPDIR/AppRun"
sed "s|@VERSION@|$VERSION|" "$SCRIPT_DIR/jellybox.desktop" > "$APPDIR/jellybox.desktop"
install -m644 "$SCRIPT_DIR/jellybox.png" "$APPDIR/jellybox.png"
ln -sf jellybox.png "$APPDIR/.DirIcon"

APPIMAGETOOL="$WORK/appimagetool.AppImage"
curl -fsSL -o "$APPIMAGETOOL" \
  https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x "$APPIMAGETOOL"

# --appimage-extract-and-run avoids needing FUSE, which CI runners lack.
"$APPIMAGETOOL" --appimage-extract-and-run "$APPDIR" "$OUT"
