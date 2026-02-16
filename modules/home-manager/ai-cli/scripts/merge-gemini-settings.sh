#!/usr/bin/env bash
# Deep-merge Nix-generated Gemini settings with existing runtime state.
# Preserves auth tokens and runtime keys while updating Nix-managed settings.
#
# Arguments:
#   $1 - Path to Nix-generated settings JSON (in /nix/store)
#   $2 - Path to target settings file (~/.gemini/settings.json)
#   $3 - Path to jq binary
#
# Merge strategy: existing runtime file as base, Nix config overlaid on top.
# This means Nix-managed keys always win, but runtime-only keys (auth tokens,
# session state) are preserved from the existing file.

set -euo pipefail

NIX_SETTINGS="${1:?Usage: merge-gemini-settings.sh <nix-settings-path> <target-path> <jq-path>}"
TARGET="${2:?Usage: merge-gemini-settings.sh <nix-settings-path> <target-path> <jq-path>}"
JQ="${3:?Usage: merge-gemini-settings.sh <nix-settings-path> <target-path> <jq-path>}"

TARGET_DIR=$(dirname "$TARGET")
mkdir -p "$TARGET_DIR"

if [[ -f "$TARGET" ]] && [[ ! -L "$TARGET" ]]; then
  # File exists and is a real file (not symlink) - merge
  # jq -s '.[0] * .[1]' merges deeply: [0]=existing runtime, [1]=Nix config
  # Nix config wins on conflicts, runtime-only keys are preserved
  MERGED=$("$JQ" -s '.[0] * .[1]' "$TARGET" "$NIX_SETTINGS" 2>/dev/null) || {
    # If merge fails (e.g., invalid JSON in target), just use Nix settings
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] Failed to merge existing settings, using Nix config" >&2
    cp "$NIX_SETTINGS" "$TARGET"
    chmod 600 "$TARGET"
    exit 0
  }
  printf '%s\n' "$MERGED" | "$JQ" '.' > "${TARGET}.tmp"
  mv "${TARGET}.tmp" "$TARGET"
  chmod 600 "$TARGET"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Merged Gemini settings (preserved runtime state)"
elif [[ -L "$TARGET" ]]; then
  # It's a symlink (old Nix-managed) - remove and create real file
  rm "$TARGET"
  cp "$NIX_SETTINGS" "$TARGET"
  chmod 600 "$TARGET"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Replaced Nix symlink with writable Gemini settings"
else
  # No existing file - just copy
  cp "$NIX_SETTINGS" "$TARGET"
  chmod 600 "$TARGET"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Created initial Gemini settings"
fi
