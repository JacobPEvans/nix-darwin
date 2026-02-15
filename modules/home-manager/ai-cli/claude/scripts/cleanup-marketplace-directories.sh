#!/usr/bin/env bash
# Clean up orphaned marketplace directories from previous configurations
# These were from deprecated aggregation marketplaces or renamed marketplaces
# Clean up orphaned marketplace directories using while-read pattern
# (repository rule: no for loops in shell scripts)

# Arguments:
#   $1: HOME_DIR - user's home directory
#   $@: MARKETPLACE_PATHS - space-separated list of marketplace paths to check

HOME_DIR="$1"
shift
MARKETPLACE_PATHS=("$@")

# Clean up known orphaned directories
printf '%s\n' \
  "awesome-claude-code-plugins" \
  "claudeforge-marketplace" \
  "skills" \
  "agents" \
  "local" \
  "claude-code-plugins" \
| while IFS= read -r ORPHAN; do
  ORPHAN_PATH="$HOME_DIR/.claude/plugins/marketplaces/$ORPHAN"
  if [ -e "$ORPHAN_PATH" ]; then
    BACKUP="$ORPHAN_PATH.backup"

    # Remove old backup if it exists (only keep one)
    if [ -e "$BACKUP" ]; then
      rm -rf "$BACKUP"
    fi

    # Move orphaned directory to backup
    mv "$ORPHAN_PATH" "$BACKUP"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Cleaned up orphaned marketplace directory: $ORPHAN" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Backup saved to: $BACKUP" >&2
  fi
done

# Clean up marketplace directories that conflict with Nix-managed symlinks
# This handles the case where runtime plugin installs created real directories
# that now prevent Nix from creating symlinks
for path in "${MARKETPLACE_PATHS[@]}"; do
  if [ -d "$path" ] && [ ! -L "$path" ]; then
    BACKUP="$path.backup"

    # Remove old backup if it exists (only keep one)
    if [ -e "$BACKUP" ]; then
      rm -rf "$BACKUP"
    fi

    # Move directory to backup
    mv "$path" "$BACKUP"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Cleaned up marketplace directory: $path" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Backup saved to: $BACKUP" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   After activation completes, a diff will be shown" >&2
  fi
done
