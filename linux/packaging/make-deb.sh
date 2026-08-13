#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="${1:?usage: make-deb.sh <bundle-dir> <output-deb> <version> <iteration>}"
OUT="${2:?}"
VERSION="${3:?}"
ITERATION="${4:?}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

ROOT="$WORK/root"
INSTALL_DIR="$ROOT/opt/jellybox"
mkdir -p "$INSTALL_DIR" "$ROOT/usr/bin" "$ROOT/usr/share/applications" \
  "$ROOT/usr/share/icons/hicolor/256x256/apps"

cp -a "$BUNDLE_DIR/." "$INSTALL_DIR/"

cat > "$ROOT/usr/bin/jellybox" <<'EOF'
#!/bin/sh
exec /opt/jellybox/jellybox "$@"
EOF
chmod 755 "$ROOT/usr/bin/jellybox"

sed -e "s/@VERSION@/$VERSION/" -e 's#^Exec=jellybox#Exec=/usr/bin/jellybox#' \
  "$SCRIPT_DIR/jellybox.desktop" > "$ROOT/usr/share/applications/jellybox.desktop"

cp "$SCRIPT_DIR/jellybox.png" "$ROOT/usr/share/icons/hicolor/256x256/apps/jellybox.png"

fpm -s dir -t deb \
  -C "$ROOT" \
  -n jellybox \
  -v "$VERSION" \
  --iteration "$ITERATION" \
  --architecture amd64 \
  --license AGPL-3.0 \
  --maintainer "Alex Sinelnikov" \
  --url "https://github.com/avdept/JellyBoxPlayer" \
  --description "Jellyfin client for Linux" \
  --category sound \
  --force \
  -p "$OUT" \
  .
