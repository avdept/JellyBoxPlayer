#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="${1:?usage: make-rpm.sh <bundle-dir> <output-rpm> <version> <iteration>}"
OUT="${2:?}"
VERSION="${3:?}"
ITERATION="${4:?}"

case "$(uname -m)" in
  x86_64)  ARCH=x86_64 ;;
  aarch64) ARCH=aarch64 ;;
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

# See make-deb.sh for why these are needed. Names below are the Fedora/RHEL
# spellings; openSUSE calls gtk3 "libgtk-3-0" and librsvg2 "librsvg-2-2", and
# fpm has no way to express an rpm dependency alternation, so this rpm targets
# the Fedora family.
fpm -s dir -t rpm \
  -C "$ROOT" \
  -n jellybox \
  -d gtk3 \
  -d librsvg2 \
  -d libglvnd-egl \
  -d mesa-libgbm \
  -d libdrm \
  -d libwayland-client \
  -d libwayland-cursor \
  -d libwayland-egl \
  -d shared-mime-info \
  -d hicolor-icon-theme \
  -d adwaita-icon-theme \
  -d libsecret \
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
