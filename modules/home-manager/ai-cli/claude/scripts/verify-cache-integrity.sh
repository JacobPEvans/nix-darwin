#!/usr/bin/env bash
# Verify Claude Code plugin cache integrity after Nix rebuilds
# Removes stale cache entries when marketplace store paths change
#
# When Nix updates marketplace symlinks to new /nix/store paths,
# Claude Code's cached plugin data becomes stale and must be purged.
# See: https://github.com/anthropics/claude-code/issues/17361

set -euo pipefail

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
for entry in "$MARKETPLACES_DIR"/*; do
  [[ -L "$entry" ]] || continue
  name=$(basename "$entry")
  target=$(readlink "$entry")

  # Hash the store path string (not file contents - that's what matters for staleness)
  hash=$(printf '%s' "$target" | shasum -a 256 | cut -d' ' -f1)
  new_hashes["$name"]="$hash"

  if [[ "${old_hashes[$name]:-}" != "$hash" ]]; then
    if [[ -d "$CACHE_DIR/$name" ]]; then
      rm -rf "$CACHE_DIR/$name"
      echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Purged stale cache: $name" >&2
      echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Store path changed to: $target" >&2
    fi
  fi
done

# Write updated hashes
mkdir -p "$CACHE_DIR"
: > "$HASH_FILE"
for name in "${!new_hashes[@]}"; do
  echo "${name}=${new_hashes[$name]}" >> "$HASH_FILE"
done
