#!/usr/bin/env bash
# Verify cache integrity for Nix-managed marketplaces
# If the marketplace source changes (e.g., flake update), delete stale cache
#
# Addresses upstream bug where stale cache prevents updated plugins from loading
# GitHub issue: anthropics/claude-code#17361
#
# Arguments:
#   $1: HOME_DIR - user's home directory
#   $2: COREUTILS_BIN - path to coreutils bin directory
#   $@: MARKETPLACE_PATHS - space-separated list of marketplace paths

HOME_DIR="$1"
COREUTILS_BIN="$2"
shift 2
MARKETPLACE_PATHS=("$@")

for path in "${MARKETPLACE_PATHS[@]}"; do
  if [ -L "$path" ]; then
    MARKETPLACE_NAME=$("$COREUTILS_BIN/basename" "$path")
    SYMLINK_TARGET=$("$COREUTILS_BIN/readlink" -f "$path")
    MARKER_FILE="$HOME_DIR/.claude/plugins/.nix-cache-marker-$MARKETPLACE_NAME"
    CACHE_DIR="$HOME_DIR/.claude/plugins/cache/$MARKETPLACE_NAME"

    # Compute hash of symlink target path
    # Using path hash (not content hash) because it's deterministic and fast
    CURRENT_HASH=$(echo "$SYMLINK_TARGET" | "$COREUTILS_BIN/sha256sum" | "$COREUTILS_BIN/cut" -d' ' -f1)

    # Check if marker exists and matches
    if [ -f "$MARKER_FILE" ]; then
      STORED_HASH=$(cat "$MARKER_FILE")
      if [ "$STORED_HASH" != "$CURRENT_HASH" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Cache invalidation: $MARKETPLACE_NAME (source changed)" >&2
        if [ -d "$CACHE_DIR" ]; then
          rm -rf "$CACHE_DIR"
          echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Removed stale cache: $CACHE_DIR" >&2
        fi
        echo "$CURRENT_HASH" > "$MARKER_FILE"
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Updated cache marker" >&2
      fi
    else
      # No marker exists - create one
      echo "$CURRENT_HASH" > "$MARKER_FILE"
      echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Created cache marker for $MARKETPLACE_NAME" >&2
    fi
  fi
done
