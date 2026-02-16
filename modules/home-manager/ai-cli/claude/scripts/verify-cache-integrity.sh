#!/usr/bin/env bash
# Verify Claude Code plugin cache integrity after Nix rebuilds
# Removes stale cache entries when marketplace store paths change
#
# When Nix updates marketplace symlinks to new /nix/store paths,
# Claude Code's cached plugin data becomes stale and must be purged.
# See: https://github.com/anthropics/claude-code/issues/17361

set -euo pipefail

# Centralized logging function (stderr for diagnostics)
log_info() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >&2
}

HOME_DIR="${1:?Usage: verify-cache-integrity.sh <home-dir>}"
MARKETPLACES_DIR="$HOME_DIR/.claude/plugins/marketplaces"
CACHE_DIR="$HOME_DIR/.claude/plugins/cache"
HASH_FILE="$CACHE_DIR/.nix-store-hashes"

# Only run if both dirs exist
[[ -d "$MARKETPLACES_DIR" ]] || exit 0
[[ -d "$CACHE_DIR" ]] || exit 0

# Load existing hashes
declare -A old_hashes
if [[ -f "$HASH_FILE" ]]; then
  while IFS='=' read -r key value; do
    [[ -n "$key" ]] && old_hashes["$key"]="$value"
  done < "$HASH_FILE"
fi

# Build new hashes, purge stale caches
declare -A new_hashes
find "$MARKETPLACES_DIR" -maxdepth 1 -type l -print0 | while IFS= read -d $'\0' -r entry; do
  name=$(basename "$entry")
  target=$(readlink "$entry")

  # Hash the store path string (not file contents - that's what matters for staleness)
  hash=$(printf '%s' "$target" | shasum -a 256 | cut -d' ' -f1)
  new_hashes["$name"]="$hash"

  if [[ "${old_hashes[$name]:-}" != "$hash" ]]; then
    if [[ -d "$CACHE_DIR/$name" ]]; then
      rm -rf "$CACHE_DIR/$name"
      log_info "Purged stale cache: $name"
      log_info "  Store path changed to: $target"
    fi
  fi
done

# Write updated hashes atomically to avoid leaving a partially written file
mkdir -p "$CACHE_DIR"
tmp_hash_file="$(mktemp "${HASH_FILE}.XXXXXX")"
for name in "${!new_hashes[@]}"; do
  echo "${name}=${new_hashes[$name]}" >> "$tmp_hash_file"
done
mv "$tmp_hash_file" "$HASH_FILE"
