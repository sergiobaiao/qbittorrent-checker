#!/usr/bin/env bash
set -euo pipefail

QBT_URL="${QBT_URL:-http://127.0.0.1:8082}" #verify your qbittorrent API port
TORRENT_HASH="${1:?missing torrent hash}"
EXCLUDED_LIST_FILE="${EXCLUDED_LIST_FILE:-/config/excluded-files.txt}"

MAX_TRIES="${MAX_TRIES:-30}"
SLEEP_SECONDS="${SLEEP_SECONDS:-2}"

curl_api() {
  curl -sS \
    --connect-timeout 3 \
    --max-time 10 \
    -H "Referer: $QBT_URL" \
    "$@"
}

post_api() {
  curl -sS \
    --connect-timeout 3 \
    --max-time 10 \
    -H "Referer: $QBT_URL" \
    "$@"
}

if [[ ! -f "$EXCLUDED_LIST_FILE" ]]; then
  echo "Excluded list file not found: $EXCLUDED_LIST_FILE" >&2
  exit 1
fi

mapfile -t excluded_patterns < <(
  sed 's/\r$//' "$EXCLUDED_LIST_FILE" |
  awk 'NF && $1 !~ /^#/'
)

if [[ ${#excluded_patterns[@]} -eq 0 ]]; then
  echo "Excluded list is empty"
  exit 0
fi

files_json=""
file_count=0

for ((i=1; i<=MAX_TRIES; i++)); do
  files_json="$(curl_api "$QBT_URL/api/v2/torrents/files?hash=$TORRENT_HASH" || true)"

  if jq -e 'type == "array"' >/dev/null 2>&1 <<<"$files_json"; then
    file_count="$(jq 'length' <<<"$files_json" 2>/dev/null || echo 0)"

    if [[ "$file_count" -gt 0 ]]; then
      echo "Got file list for torrent $TORRENT_HASH after $i attempt(s) ($file_count file(s))"
      break
    fi
  fi

  sleep "$SLEEP_SECONDS"
done

if ! jq -e 'type == "array"' >/dev/null 2>&1 <<<"$files_json"; then
  echo "Could not get valid file list for torrent $TORRENT_HASH" >&2
  exit 1
fi

file_count="$(jq 'length' <<<"$files_json" 2>/dev/null || echo 0)"
if [[ "$file_count" -eq 0 ]]; then
  echo "File list still empty for torrent $TORRENT_HASH after $MAX_TRIES attempts"
  exit 0
fi

matched_file=""
matched_pattern=""

while IFS= read -r file_name; do
  lower_file="$(printf '%s' "$file_name" | tr '[:upper:]' '[:lower:]')"

  for pattern in "${excluded_patterns[@]}"; do
    lower_pattern="$(printf '%s' "$pattern" | tr '[:upper:]' '[:lower:]')"

    # trim whitespace
    lower_pattern="${lower_pattern#"${lower_pattern%%[![:space:]]*}"}"
    lower_pattern="${lower_pattern%"${lower_pattern##*[![:space:]]}"}"

    [[ -z "$lower_pattern" ]] && continue

    if [[ "$lower_file" == $lower_pattern ]]; then
      matched_file="$file_name"
      matched_pattern="$pattern"
      break 2
    fi
  done
done < <(jq -r '.[].name' <<<"$files_json")

if [[ -n "$matched_file" ]]; then
  echo "Matched excluded pattern: $matched_pattern -> $matched_file"

  post_api \
    -X POST \
    --data-urlencode "hashes=$TORRENT_HASH" \
    --data-urlencode "deleteFiles=true" \
    "$QBT_URL/api/v2/torrents/delete" >/dev/null

  echo "Torrent $TORRENT_HASH deleted because of excluded file: $matched_file"
  exit 0
fi

echo "No excluded files found in torrent $TORRENT_HASH"
exit 0
