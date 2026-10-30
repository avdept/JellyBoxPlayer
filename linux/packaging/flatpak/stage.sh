#!/usr/bin/env bash
set -euo pipefail

# Fills linux/packaging/flatpak/stage/ with everything the manifest installs:
# the finished Flutter bundle plus the desktop entry, icon and metainfo named
# after the app id, which is what flatpak-builder exports. Build with
#   flatpak-builder --user --install --force-clean build-dir \
#     linux/packaging/flatpak/com.prodigytech.jellybox.yml

BUNDLE_DIR="${1:?usage: stage.sh <bundle-dir> <version>}"
VERSION="${2:?}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGING_DIR="$(dirname "$SCRIPT_DIR")"
STAGE="$SCRIPT_DIR/stage"

rm -rf "$STAGE"
mkdir -p "$STAGE/bundle"
cp -a "$BUNDLE_DIR/." "$STAGE/bundle/"

sed -e '/^X-AppImage-Version=/d' \
    -e 's/^Icon=jellybox$/Icon=com.prodigytech.jellybox/' \
  "$PACKAGING_DIR/com.prodigytech.jellybox.desktop" > "$STAGE/com.prodigytech.jellybox.desktop"

sed -e "s|@VERSION@|$VERSION|" -e "s|@DATE@|$(date -u +%Y-%m-%d)|" \
  "$SCRIPT_DIR/com.prodigytech.jellybox.metainfo.xml" > "$STAGE/com.prodigytech.jellybox.metainfo.xml"

cp "$PACKAGING_DIR/jellybox.png" "$STAGE/com.prodigytech.jellybox.png"

cat > "$STAGE/jellybox" <<'EOF'
#!/bin/sh
exec /app/lib/jellybox/jellybox "$@"
EOF
chmod 755 "$STAGE/jellybox"

echo "Staged $(du -sh "$STAGE" | cut -f1) into $STAGE"
