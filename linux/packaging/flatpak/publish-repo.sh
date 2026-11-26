#!/usr/bin/env bash
set -euo pipefail

# Adds released .flatpak bundles to the signed OSTree repo on R2 and refreshes
# the .flatpakref/.flatpakrepo next to it. Each bundle becomes a new commit on
# top of the ref already in the repo, so history and static deltas carry over.
#
# Needs: flatpak, ostree, gpg, aws.
# Env:   R2_ACCOUNT_ID, R2_BUCKET, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
#        FLATPAK_GPG_PRIVATE_KEY (armored, no passphrase),
#        FLATPAK_PUBLIC_URL (default https://flatpak.jellybox.app),
#        FLATPAK_PRUNE_DEPTH (default 3).

[ $# -gt 0 ] || { echo "usage: publish-repo.sh <bundle.flatpak>..." >&2; exit 2; }
: "${R2_ACCOUNT_ID:?}" "${R2_BUCKET:?}" "${AWS_ACCESS_KEY_ID:?}" "${AWS_SECRET_ACCESS_KEY:?}"
: "${FLATPAK_GPG_PRIVATE_KEY:?}"

APP_ID=com.prodigytech.jellybox
BRANCH=master
PUBLIC_URL="${FLATPAK_PUBLIC_URL:-https://flatpak.jellybox.app}"
PUBLIC_URL="${PUBLIC_URL%/}"
PRUNE_DEPTH="${FLATPAK_PRUNE_DEPTH:-3}"

export AWS_DEFAULT_REGION=auto
export AWS_REQUEST_CHECKSUM_CALCULATION=when_required
export AWS_RESPONSE_CHECKSUM_VALIDATION=when_required
ENDPOINT="https://$R2_ACCOUNT_ID.r2.cloudflarestorage.com"
DEST="s3://$R2_BUCKET"
s3() { aws s3 "$@" --endpoint-url "$ENDPOINT" --only-show-errors; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

export GNUPGHOME="$WORK/gnupg"
mkdir -m 700 "$GNUPGHOME"
printf '%s\n' "$FLATPAK_GPG_PRIVATE_KEY" | gpg --batch --quiet --import
KEY_ID="$(gpg --list-secret-keys --with-colons | awk -F: '/^fpr:/ { print $10; exit }')"
[ -n "$KEY_ID" ] || { echo "No secret key in FLATPAK_GPG_PRIVATE_KEY" >&2; exit 1; }
SIGN=(--gpg-sign="$KEY_ID" --gpg-homedir="$GNUPGHOME")

REPO="$WORK/repo"
mkdir -p "$REPO"
s3 sync "$DEST/repo" "$REPO"
if [ -f "$REPO/config" ]; then
  # S3 has no empty directories; ostree expects these to exist.
  mkdir -p "$REPO"/{objects,tmp,state,extensions,refs/heads,refs/mirrors,refs/remotes}
  echo "Existing repo refs:"
  ostree refs --repo="$REPO" | sed 's/^/  /'
else
  echo "No repo in $DEST/repo yet, creating one"
  ostree init --mode=archive-z2 --repo="$REPO"
fi

for bundle in "$@"; do
  incoming="$WORK/incoming"
  rm -rf "$incoming"
  ostree init --mode=archive-z2 --repo="$incoming"
  flatpak build-import-bundle --no-update-summary "$incoming" "$bundle"
  for ref in $(ostree refs --repo="$incoming" | grep -E "^(app|runtime)/$APP_ID[^/]*/[^/]+/$BRANCH\$"); do
    echo "Committing $ref from $(basename "$bundle")"
    flatpak build-commit-from --no-update-summary "${SIGN[@]}" \
      --src-repo="$incoming" "$REPO" "$ref"
  done
done

flatpak build-update-repo "${SIGN[@]}" \
  --title=JellyBox \
  --default-branch="$BRANCH" \
  --generate-static-deltas \
  --prune --prune-depth="$PRUNE_DEPTH" \
  "$REPO"

# Content-addressed files go first, so the summary published after them never
# points at something that is not there yet. Deletions from pruning go last.
METADATA=(summary 'summary.*' 'summaries/*' 'refs/*' 'delta-indexes/*' config)
LOCAL_ONLY=(--exclude 'tmp/*' --exclude 'state/*' --exclude 'extensions/*')
exclude_metadata=(); include_metadata=()
for m in "${METADATA[@]}"; do
  exclude_metadata+=(--exclude "$m")
  include_metadata+=(--include "$m")
done

s3 sync "$REPO" "$DEST/repo" "${LOCAL_ONLY[@]}" "${exclude_metadata[@]}" \
  --cache-control 'public, max-age=31536000, immutable'
s3 sync "$REPO" "$DEST/repo" --exclude '*' "${include_metadata[@]}" \
  --cache-control 'no-cache'
s3 sync "$REPO" "$DEST/repo" "${LOCAL_ONLY[@]}" --size-only --delete

GPG_KEY="$(gpg --export "$KEY_ID" | base64 -w0)"

cat > "$WORK/jellybox.flatpakref" <<EOF
[Flatpak Ref]
Name=$APP_ID
Branch=$BRANCH
Title=JellyBox
Url=$PUBLIC_URL/repo/
SuggestRemoteName=jellybox
Homepage=https://jellybox.app
IsRuntime=false
RuntimeRepo=https://dl.flathub.org/repo/flathub.flatpakrepo
GPGKey=$GPG_KEY
EOF

cat > "$WORK/jellybox.flatpakrepo" <<EOF
[Flatpak Repo]
Title=JellyBox
Url=$PUBLIC_URL/repo/
Homepage=https://jellybox.app
Comment=JellyBox music player
DefaultBranch=$BRANCH
GPGKey=$GPG_KEY
EOF

gpg --armor --export "$KEY_ID" > "$WORK/jellybox.gpg"

s3 cp "$WORK/jellybox.flatpakref" "$DEST/jellybox.flatpakref" \
  --content-type application/vnd.flatpak.ref --cache-control no-cache
s3 cp "$WORK/jellybox.flatpakrepo" "$DEST/jellybox.flatpakrepo" \
  --content-type application/vnd.flatpak.repo --cache-control no-cache
s3 cp "$WORK/jellybox.gpg" "$DEST/jellybox.gpg" \
  --content-type application/pgp-keys --cache-control no-cache

echo "Published. Install with:"
echo "  flatpak install --user $PUBLIC_URL/jellybox.flatpakref"
