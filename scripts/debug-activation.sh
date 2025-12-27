#!/usr/bin/env bash
# Debug Activation Script
#
# This script helps debug why /run/current-system isn't being updated
# during darwin-rebuild switch.
#
# Usage: ./scripts/debug-activation.sh

set -euo pipefail

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Activation Debugging Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Current state
echo "1. Current System State:"
echo "   /run/current-system -> $(readlink /run/current-system)"
echo "   /nix/var/nix/profiles/system -> $(readlink /nix/var/nix/profiles/system)"
echo ""

# Latest generation
LATEST_GEN=$(readlink /nix/var/nix/profiles/system)
LATEST_PATH=$(readlink "/nix/var/nix/profiles/$LATEST_GEN")
echo "2. Latest Generation:"
echo "   Generation: $LATEST_GEN"
echo "   Store Path: $LATEST_PATH"
echo ""

# Check if they match
CURRENT_PATH=$(readlink -f /run/current-system)
if [ "$CURRENT_PATH" = "$LATEST_PATH" ]; then
  echo "✅ Status: SYNCHRONIZED - /run/current-system points to latest generation"
else
  echo "❌ Status: OUT OF SYNC"
  echo "   Current:  $CURRENT_PATH"
  echo "   Expected: $LATEST_PATH"
fi
echo ""

# Check permissions
echo "3. Permission Analysis:"
echo "   /run ownership: $(stat -f "%Su:%Sg" /run)"
echo "   /run permissions: $(stat -f "%Sp" /run)"
echo "   /run/current-system ownership: $(stat -f "%Su:%Sg" /run/current-system)"
echo "   /run/current-system permissions: $(stat -f "%Sp" /run/current-system)"
echo "   Current user: $(whoami)"
echo "   Running as root: $(if [ "$(id -u)" -eq 0 ]; then echo "YES"; else echo "NO"; fi)"
echo ""

# Test if we can update the symlink
echo "4. Symlink Update Test:"
if [ "$(id -u)" -eq 0 ]; then
  echo "   Testing ln -sfn command..."
  if ln -sfn "$LATEST_PATH" /run/current-system 2>/dev/null; then
    echo "   ✅ SUCCESS: Symlink updated"
    UPDATED_PATH=$(readlink -f /run/current-system)
    if [ "$UPDATED_PATH" = "$LATEST_PATH" ]; then
      echo "   ✅ VERIFICATION: Symlink points to correct path"
    else
      echo "   ❌ VERIFICATION FAILED: Symlink points to $UPDATED_PATH"
    fi
  else
    echo "   ❌ FAILED: Could not update symlink"
    echo "   Error: $?"
  fi
else
  echo "   ⚠️  SKIPPED: Not running as root (re-run with sudo to test)"
fi
echo ""

# Check activate script
echo "5. Activate Script Analysis:"
ACTIVATE_SCRIPT="/nix/var/nix/profiles/system/activate"
if [ -f "$ACTIVATE_SCRIPT" ]; then
  echo "   Activate script exists: YES"
  echo "   Activate script location: $ACTIVATE_SCRIPT"

  # Check if ln -sfn command is in the script
  if grep -q "ln -sfn.*current-system" "$ACTIVATE_SCRIPT"; then
    echo "   ✅ ln -sfn command found in activate script"
    LINE_NUM=$(grep -n "ln -sfn.*current-system" "$ACTIVATE_SCRIPT" | head -1 | cut -d: -f1)
    echo "   Line number: $LINE_NUM"
  else
    echo "   ❌ ln -sfn command NOT found in activate script"
  fi
else
  echo "   ❌ Activate script not found"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Recommendations:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$CURRENT_PATH" != "$LATEST_PATH" ]; then
  echo ""
  echo "To fix the out-of-sync state, run:"
  echo "  sudo $ACTIVATE_SCRIPT"
  echo ""
  echo "Or manually update the symlink:"
  echo "  sudo ln -sfn $LATEST_PATH /run/current-system"
  echo ""
fi

echo "To capture full activation output during rebuild:"
echo "  sudo darwin-rebuild switch --flake ~/.config/nix 2>&1 | tee /tmp/darwin-rebuild-debug.log"
echo ""
