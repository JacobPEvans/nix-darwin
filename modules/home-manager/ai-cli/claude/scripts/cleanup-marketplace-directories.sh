#!/usr/bin/env bash
# Clean up orphaned marketplace directories from previous configurations
# Backs up both deprecated marketplaces and conflicting real directories

# Arguments:
#   $1: HOME_DIR - user's home directory
#   $@: MARKETPLACE_PATHS - space-separated list of marketplace paths to check

set -euo pipefail

HOME_DIR="$1"
shift
MARKETPLACE_PATHS=("$@")

# Backup a directory with timestamp if it exists
backup_if_exists() {
  local path="$1"
  if [ -e "$path" ]; then
    local backup="${path}.backup"
    [ -e "$backup" ] && rm -rf "$backup"
    mv "$path" "$backup"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Backed up: ${path##*/} → $backup" >&2
  fi
}

# Backup deprecated/orphaned marketplaces
printf '%s\n' awesome-claude-code-plugins claudeforge-marketplace skills agents local claude-code-plugins | while IFS= read -r orphan; do
  backup_if_exists "$HOME_DIR/.claude/plugins/marketplaces/$orphan"
done

# Backup real directories that conflict with Nix-managed symlinks
printf '%s\n' "${MARKETPLACE_PATHS[@]}" | while IFS= read -r path; do
  if [ -d "$path" ] && [ ! -L "$path" ]; then
    backup_if_exists "$path"
  fi
done
