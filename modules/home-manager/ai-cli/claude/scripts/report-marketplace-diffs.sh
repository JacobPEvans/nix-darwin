#!/usr/bin/env bash
# Show diffs between backed-up directories and new Nix-managed symlinks
# Backups are kept for manual review and deletion
#
# Arguments:
#   $1: COREUTILS_BIN - path to coreutils binaries
#   $@: Marketplace paths to check

set -euo pipefail

COREUTILS_BIN="$1"
shift

printf '%s\n' "$@" | while IFS= read -r path; do
  BACKUP="$path.backup"
  [ ! -d "$BACKUP" ] && continue

  echo "" >&2
  echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Marketplace transition: $path" >&2

  # Check symlink validity directly instead of checking target separately
  if [ ! -e "$path" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] Symlink target does not exist" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] Cannot compare directories" >&2
    continue
  fi

  if [ ! -L "$path" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] Not a symlink" >&2
    continue
  fi

  NEW_TARGET=$("$COREUTILS_BIN/readlink" "$path")
  echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Was: Real directory (runtime)" >&2
  echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Now: Symlink → $NEW_TARGET (Nix)" >&2

  # Show diff (first 20 lines) with proper exit code handling
  # Capture diff output first to avoid SIGPIPE issues with head
  diff_output=$(diff -r "$BACKUP" "$path" 2>&1 || true)
  diff_truncated=$(echo "$diff_output" | head -20)
  if [ -z "$diff_truncated" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Directories identical" >&2
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Differences (first 20 lines):" >&2
    echo "$diff_truncated" >&2
  fi

  echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Backup: $BACKUP (review and delete when done)" >&2
done
