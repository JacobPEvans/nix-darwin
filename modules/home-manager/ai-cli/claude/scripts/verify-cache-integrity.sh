#!/usr/bin/env bash
# Verify cache integrity for Nix-managed marketplaces
# If the marketplace source changes (e.g., flake update), delete stale cache
# Addresses upstream bug where stale cache prevents updated plugins from loading
# GitHub issue: anthropics/claude-code#17361

set -euo pipefail

HOME_DIR="$1"
COREUTILS_BIN="$2"
shift 2

printf '%s\n' "$@" | while IFS= read -r path; do
  [ ! -L "$path" ] && continue

  MARKETPLACE_NAME=$("$COREUTILS_BIN/basename" "$path")
  SYMLINK_TARGET=$("$COREUTILS_BIN/readlink" -f "$path")
  MARKER_FILE="$HOME_DIR/.claude/plugins/.nix-cache-marker-$MARKETPLACE_NAME"
  CACHE_DIR="$HOME_DIR/.claude/plugins/cache/$MARKETPLACE_NAME"

  # Hash the symlink target path for change detection
  CURRENT_HASH=$(echo "$SYMLINK_TARGET" | "$COREUTILS_BIN/sha256sum" | "$COREUTILS_BIN/cut" -d' ' -f1)

  # Check if cache marker exists and compare
  STORED_HASH=$([ -f "$MARKER_FILE" ] && cat "$MARKER_FILE" || echo "")

  if [ "$STORED_HASH" != "$CURRENT_HASH" ]; then
    [ -d "$CACHE_DIR" ] && rm -rf "$CACHE_DIR"
    echo "$CURRENT_HASH" > "$MARKER_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Cache updated: $MARKETPLACE_NAME" >&2
  fi
done
