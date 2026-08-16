#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="${1:?usage: bundle-libs.sh <bundle-dir>}"
LIB_DIR="$BUNDLE_DIR/lib"
BIN="$BUNDLE_DIR/jellybox"

mkdir -p "$LIB_DIR"

# Fail the build rather than shipping a bundle that only starts on machines
# with libsqlite3-dev installed. See the NATIVE_ASSETS_DIR block in
# linux/CMakeLists.txt for why this can go missing.
if [ ! -f "$LIB_DIR/libsqlite3.so" ]; then
  echo "error: $LIB_DIR/libsqlite3.so is missing." >&2
  echo "       The package:sqlite3 native asset was not installed into the bundle;" >&2
  echo "       check the NATIVE_ASSETS_DIR install() rule in linux/CMakeLists.txt." >&2
  exit 1
fi

EXCLUDE_RE='^(linux-vdso\.so.*|ld-linux.*\.so.*|libc\.so.*|libm\.so.*|libdl\.so.*|libpthread\.so.*|librt\.so.*|libresolv\.so.*|libnsl\.so.*|libutil\.so.*|libnss_.*|libGL\.so.*|libGLX.*|libEGL.*|libGLdispatch.*|libgbm\.so.*|libdrm.*|libvulkan.*|libnvidia.*|libva.*|libvdpau.*|libwayland-egl.*|libwayland-client.*|libwayland-cursor.*)$'

# Emits "<soname>\t<resolved-path>" for each non-excluded dependency of $1.
resolve_deps() {
  ldd "$1" 2>/dev/null | awk '{print $1, $3}' | while read -r name path; do
    [ -z "$path" ] && continue
    [ "$path" = "not" ] && continue
    base="$(basename "$name")"
    [[ "$base" =~ $EXCLUDE_RE ]] && continue
    printf '%s\t%s\n' "$name" "$path"
  done || true
}

declare -A SEEN
queue=()

# Seeds: the main binary and everything already installed by CMake. These
# are scanned for further deps but never re-copied (they're already
# correctly named/placed).
for f in "$BIN" "$LIB_DIR"/*; do
  [ -f "$f" ] && queue+=($'\t'"$f")
done

# Seed libs that are dlopen()'d at runtime and never show up in `ldd`.
#
# Note: libsqlite3 is deliberately NOT seeded from the host. package:sqlite3
# ships it as a native asset that CMake installs into lib/ as the unversioned
# `libsqlite3.so` — the exact name the AOT snapshot dlopen()s. Pulling the
# host's libsqlite3.so.0 in here would land under the wrong name and shadow
# nothing, while masking a missing native asset during local testing.
for soname in libmpv.so.2 libmpv.so.1; do
  # awk's early `exit` closes the pipe before ldconfig finishes writing,
  # which SIGPIPEs ldconfig; with pipefail that would abort the script.
  path="$( (ldconfig -p 2>/dev/null | awk -v n="$soname" '$1==n {print $NF; exit}') || true)"
  if [ -n "${path:-}" ] && [ -f "$path" ]; then
    queue+=("$soname"$'\t'"$path")
  fi
done

while [ "${#queue[@]}" -gt 0 ]; do
  entry="${queue[0]}"
  queue=("${queue[@]:1}")
  soname="${entry%%$'\t'*}"
  path="${entry#*$'\t'}"

  real="$(readlink -f "$path")"
  [ -n "${SEEN[$real]:-}" ] && continue
  SEEN[$real]=1

  # Destination filename must match the soname other objects look it up by,
  # not the (possibly versioned) real filename it resolves to on this host.
  if [ -n "$soname" ]; then
    dest="$LIB_DIR/$soname"
    if [ ! -e "$dest" ]; then
      cp -L "$path" "$dest"
      chmod u+w "$dest"
    fi
  fi

  while IFS=$'\t' read -r dep_name dep_path; do
    [ -n "$dep_path" ] && queue+=("$dep_name"$'\t'"$dep_path")
  done < <(resolve_deps "$real")
done

# Every bundled object needs to find its siblings via $ORIGIN instead of
# whatever rpath/runpath it was originally built with. --force-rpath writes
# the legacy DT_RPATH tag instead of DT_RUNPATH: RUNPATH only resolves an
# object's own direct DT_NEEDED entries, but libmpv/libsqlite3 are pulled in
# via dlopen() on a bare soname (not a link-time dependency), and dlopen()
# only consults DT_RPATH, not DT_RUNPATH. Without this, the bundled mpv/
# sqlite3 libs would sit unused and the app would silently fall back to
# whatever (if anything) the host system has installed.
for f in "$LIB_DIR"/*; do
  [ -f "$f" ] || continue
  patchelf --force-rpath --set-rpath '$ORIGIN' "$f" 2>/dev/null || true
done
patchelf --force-rpath --set-rpath '$ORIGIN/lib' "$BIN"

echo "Bundled $(find "$LIB_DIR" -maxdepth 1 -type f | wc -l) libraries into $LIB_DIR"
