#!/usr/bin/env bash
# Activation Verification Script
# Verifies /run/current-system matches the latest system profile generation
# Exit codes: 0 = success, 1 = mismatch detected

set -euo pipefail

# Get the latest system profile generation
SYSTEM_PROFILE=$(readlink /nix/var/nix/profiles/system)
SYSTEM_PROFILE_TARGET=$(readlink -f "/nix/var/nix/profiles/${SYSTEM_PROFILE}")

# Get the current-system target
CURRENT_SYSTEM=$(readlink -f /run/current-system)

# Extract generation numbers for better output
SYSTEM_GEN=$(echo "$SYSTEM_PROFILE" | grep -oE '[0-9]+')

echo "=== System Activation Verification ===" >&2
echo "System profile:    ${SYSTEM_PROFILE} → ${SYSTEM_PROFILE_TARGET}" >&2
echo "Current system:    /run/current-system → ${CURRENT_SYSTEM}" >&2
echo "" >&2

if [[ "$SYSTEM_PROFILE_TARGET" != "$CURRENT_SYSTEM" ]]; then
  echo "❌ ACTIVATION MISMATCH DETECTED" >&2
  echo "" >&2
  echo "The system profile points to generation ${SYSTEM_GEN}, but /run/current-system" >&2
  echo "is still pointing to an older generation." >&2
  echo "" >&2
  echo "This means the activation script did not complete successfully." >&2
  echo "" >&2
  echo "To fix this, run:" >&2
  echo "  sudo /nix/var/nix/profiles/system/activate" >&2
  echo "" >&2
  exit 1
fi

echo "✅ Activation verified: /run/current-system matches system profile (generation ${SYSTEM_GEN})" >&2

# Optional: Verify key binaries match expected versions
if command -v claude &>/dev/null; then
  CLAUDE_PATH=$(which claude)
  if [[ "$CLAUDE_PATH" != "/run/current-system/sw/bin/claude" ]]; then
    echo "⚠️  WARNING: 'which claude' shows $CLAUDE_PATH instead of /run/current-system/sw/bin/claude" >&2
    echo "    Your PATH may be incorrect or a local override is present" >&2
  fi
fi

exit 0
