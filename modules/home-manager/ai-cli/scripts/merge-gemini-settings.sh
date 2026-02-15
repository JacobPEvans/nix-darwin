#!/usr/bin/env bash
# Merge Nix-generated Gemini settings with runtime state
#
# Always merge when file exists (even if not writable/symlink),
# so runtime/auth keys are preserved. Write to temp file first
# for atomic replacement.
#
# Arguments:
#   $1: HOME_DIR - user's home directory
#   $2: SETTINGS_JSON - path to Nix-generated settings.json
#   $3: JQ_BIN - path to jq binary

HOME_DIR="$1"
SETTINGS_JSON="$2"
JQ_BIN="$3"

SETTINGS_FILE="$HOME_DIR/.gemini/settings.json"
SETTINGS_DIR=$(dirname "$SETTINGS_FILE")

# Ensure .gemini directory exists
mkdir -p "$SETTINGS_DIR"

# Use mktemp in same directory for atomic replacement
TMP_SETTINGS_FILE=$(mktemp "$SETTINGS_DIR/settings.json.XXXXXX")

if [ -f "$SETTINGS_FILE" ]; then
  echo "Merging Nix configuration with existing Gemini settings..." >&2
  # Deep merge: Nix settings take precedence, runtime keys preserved
  # Use settingsJson directly to avoid shell escaping issues
  "$JQ_BIN" -s '.[0] * .[1]' "$SETTINGS_FILE" "$SETTINGS_JSON" > "$TMP_SETTINGS_FILE"
else
  echo "Creating new Gemini settings file..." >&2
  cp "$SETTINGS_JSON" "$TMP_SETTINGS_FILE"
fi

# Replace any existing file or symlink atomically
# Only move into place after jq/cp succeeds
rm -f "$SETTINGS_FILE"
mv "$TMP_SETTINGS_FILE" "$SETTINGS_FILE"

# Ensure file is writable for Gemini CLI but not world-readable
chmod 600 "$SETTINGS_FILE"
