#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="${1:?usage: make-deb.sh <bundle-dir> <output-deb> <version> <iteration>}"
OUT="${2:?}"
VERSION="${3:?}"
ITERATION="${4:?}"

case "$(uname -m)" in
  x86_64)  ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  *) echo "error: unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac

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

sed -e "s|@VERSION@|$VERSION|" -e 's#^Exec=jellybox#Exec=/usr/bin/jellybox#' \
  "$SCRIPT_DIR/jellybox.desktop" > "$ROOT/usr/share/applications/jellybox.desktop"

cp "$SCRIPT_DIR/jellybox.png" "$ROOT/usr/share/icons/hicolor/256x256/apps/jellybox.png"

# The bundle carries libmpv and libsqlite3 itself, but the GTK stack reaches
# for runtime data that lives outside any .so: gdk-pixbuf loader modules,
# /usr/share/mime, and the icon themes GTK falls back through. librsvg2-common
# is what registers the SVG pixbuf loader -- without it a KDE session running
# a Breeze (SVG-only) icon theme cannot rasterize a single icon.
fpm -s dir -t deb \
  -C "$ROOT" \
  -n jellybox \
  -d 'libgtk-3-0t64 | libgtk-3-0' \
  -d 'libgdk-pixbuf-2.0-0 | libgdk-pixbuf2.0-0' \
  -d librsvg2-common \
  -d libegl1 \
  -d libgbm1 \
  -d libdrm2 \
  -d libwayland-client0 \
  -d libwayland-cursor0 \
  -d libwayland-egl1 \
  -d shared-mime-info \
  -d hicolor-icon-theme \
  -d adwaita-icon-theme \
  -d 'libsecret-1-0' \
  -v "$VERSION" \
  --iteration "$ITERATION" \
  --architecture "$ARCH" \
  --license AGPL-3.0 \
  --maintainer "Alex Sinelnikov" \
  --url "https://github.com/avdept/JellyBoxPlayer" \
  --description "Jellyfin client for Linux" \
  --category sound \
  --force \
  -p "$OUT" \
  .
