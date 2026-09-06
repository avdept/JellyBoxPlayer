#!/usr/bin/env bash
# Fails when the working tree is configured for a build other people cannot
# reproduce: a dependency override in place, or a lock file that resolved
# upnp_quirks to somewhere other than the in-repo stub.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
status=0

if [[ -f "$root/pubspec_overrides.yaml" ]]; then
  echo "pubspec_overrides.yaml is present; run 'flutter pub get' without it before committing pubspec.lock" >&2
  status=1
fi

if ! grep -q 'path: "packages/upnp_quirks"' "$root/pubspec.lock"; then
  echo "pubspec.lock does not resolve upnp_quirks to the in-repo stub:" >&2
  grep -A6 '^  upnp_quirks:' "$root/pubspec.lock" >&2 || true
  echo "restore it with: rm -f pubspec_overrides.yaml && flutter pub get" >&2
  status=1
fi

if [[ $status -eq 0 ]]; then
  echo "pubspec.lock is buildable without the private upnp_quirks table"
fi
exit $status
