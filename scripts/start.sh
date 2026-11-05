#!/usr/bin/env bash
set -Eeuo pipefail
cd /home/container

readonly REPO="Ravalink-Project/Ravalink"
readonly API_URL="https://api.github.com/repos/${REPO}/releases?per_page=20"

fail() {
  printf '[RavaLink] ERROR: %s\n' "$*" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || fail "curl is missing from the selected Docker image."
command -v jq >/dev/null 2>&1 || fail "jq is missing from the selected Docker image."

if [[ -z "${RAVALINK_PASSWORD:-}" || "${RAVALINK_PASSWORD}" == CHANGE_ME_* ]]; then
  fail "Set a unique RAVALINK_PASSWORD (at least 16 characters) in the panel before starting."
fi
if (( ${#RAVALINK_PASSWORD} < 16 )); then
  fail "RAVALINK_PASSWORD must contain at least 16 characters."
fi

case "$(uname -m)" in
  x86_64|amd64) asset_name="ravalink-linux-x86_64" ;;
  aarch64|arm64) asset_name="ravalink-linux-aarch64" ;;
  *) fail "Unsupported CPU architecture: $(uname -m). Supported: x86_64 and aarch64." ;;
esac

printf '[RavaLink] Checking the latest published GitHub release...\n'
response="$(curl --silent --show-error --location --retry 3 --retry-all-errors --connect-timeout 10 --max-time 60 --write-out '%{http_code}__HTTP_STATUS__' -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' "$API_URL")" || fail "Could not query GitHub Releases. Check network access and GitHub API availability."
http_status="${response##*__HTTP_STATUS__}"
release_json="${response%__HTTP_STATUS__*}"
[[ "$http_status" == "200" ]] || fail "GitHub Releases returned HTTP $http_status."

# The first published release may be an RC. Select the newest published
# release, including prereleases, while never selecting a draft.
release_json="$(jq -cer 'map(select(.draft == false)) | first // empty' <<< "$release_json")" || fail "No published GitHub Release has been published in $REPO yet."
tag="$(jq -er '.tag_name // empty' <<< "$release_json")" || fail "GitHub returned a release without a tag."
asset_url="$(jq -er --arg name "$asset_name" '[.assets[]? | select(.name == $name) | .browser_download_url][0] // empty' <<< "$release_json")" || fail "Release $tag does not contain the required asset: $asset_name."
checksums_url="$(jq -er '[.assets[]? | select(.name == "SHA256SUMS") | .browser_download_url][0] // empty' <<< "$release_json")" || fail "Release $tag does not contain SHA256SUMS."

tmp_file="$(mktemp ./ravalink.download.XXXXXX)"
tmp_checksums="$(mktemp ./SHA256SUMS.download.XXXXXX)"
trap 'rm -f "$tmp_file" "$tmp_checksums"' EXIT
curl --fail --silent --show-error --location --retry 3 --retry-all-errors --connect-timeout 10 --max-time 120 "$checksums_url" -o "$tmp_checksums" || fail "Checksum download failed for release $tag."
expected_hash="$(awk -v name="$asset_name" '($2 == name || $2 == ("*" name)) { print $1; exit }' "$tmp_checksums")"
[[ "$expected_hash" =~ ^[[:xdigit:]]{64}$ ]] || fail "SHA256SUMS does not contain a valid checksum for $asset_name."

current_tag=""
[[ ! -f .ravalink-release ]] || current_tag="$(cat .ravalink-release)"

if [[ -x ./ravalink && "$current_tag" == "$tag" ]] \
  && printf '%s  %s\n' "$expected_hash" "./ravalink" | sha256sum --check --status; then
  printf '[RavaLink] Release %s is already installed and checksum verified.\\n' "$tag"
else
  printf '[RavaLink] Installing %s (%s)...\\n' "$tag" "$asset_name"
  curl --fail --silent --show-error --location --retry 3 --retry-all-errors --connect-timeout 10 --max-time 1200 "$asset_url" -o "$tmp_file" || fail "Download failed for release $tag."
  [[ -s "$tmp_file" ]] || fail "GitHub returned an empty binary for release $tag."
  printf '%s  %s\n' "$expected_hash" "$tmp_file" | sha256sum --check --status || fail "SHA-256 verification failed for release $tag."
  chmod 0755 "$tmp_file"
  mv -f "$tmp_file" ./ravalink
  printf '%s\\n' "$tag" > .ravalink-release
  printf '[RavaLink] Successfully installed and verified release %s.\n' "$tag"
fi

export RAVALINK_ADDRESS="${RAVALINK_ADDRESS:-0.0.0.0}"
export RAVALINK_PORT="${RAVALINK_PORT:-2333}"
export RAVALINK_LOG_LEVEL="${RAVALINK_LOG_LEVEL:-info}"
printf '[RavaLink] Starting %s on %s:%s...\n' "$tag" "$RAVALINK_ADDRESS" "$RAVALINK_PORT"
exec ./ravalink
