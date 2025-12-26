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

echo "=== System Activation Verification ==="
echo "System profile:    ${SYSTEM_PROFILE} → ${SYSTEM_PROFILE_TARGET}"
echo "Current system:    /run/current-system → ${CURRENT_SYSTEM}"
echo ""

if [[ "$SYSTEM_PROFILE_TARGET" != "$CURRENT_SYSTEM" ]]; then
  echo "❌ ACTIVATION MISMATCH DETECTED"
  echo ""
  echo "The system profile points to generation ${SYSTEM_GEN}, but /run/current-system"
  echo "is still pointing to an older generation."
  echo ""
  echo "This means the activation script did not complete successfully."
  echo ""
  echo "To fix this, run:"
  echo "  sudo /nix/var/nix/profiles/system/activate"
  echo ""
  exit 1
fi

echo "✅ Activation verified: /run/current-system matches system profile (generation ${SYSTEM_GEN})"

# Optional: Verify key binaries match expected versions
if command -v claude &>/dev/null; then
  CLAUDE_PATH=$(which claude)
  if [[ "$CLAUDE_PATH" != "/run/current-system/sw/bin/claude" ]]; then
    echo "⚠️  WARNING: 'which claude' shows $CLAUDE_PATH instead of /run/current-system/sw/bin/claude"
    echo "    Your PATH may be incorrect or a local override is present"
  fi
fi

exit 0
