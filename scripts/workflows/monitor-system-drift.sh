#!/usr/bin/env bash
# System Drift Monitoring Script
# Checks if running binaries match expected versions from system profile
# Can be run via cron or launchd for continuous monitoring
# Exit codes: 0 = no drift, 1 = drift detected

set -euo pipefail

# Packages to monitor with expected sources
CRITICAL_PACKAGES=(
  "claude"
  "claude-monitor"
  "gemini-cli"
  "git"
  "gh"
)

echo "=== System Drift Monitor ==="
echo "Date: $(date)"
echo ""

DRIFT_DETECTED=0

# Check activation state first
SYSTEM_PROFILE_TARGET=$(readlink -f /nix/var/nix/profiles/system)
CURRENT_SYSTEM=$(readlink -f /run/current-system)

if [[ "$SYSTEM_PROFILE_TARGET" != "$CURRENT_SYSTEM" ]]; then
  echo "❌ CRITICAL: Activation mismatch detected"
  echo "   System profile: $SYSTEM_PROFILE_TARGET"
  echo "   Current system: $CURRENT_SYSTEM"
  echo ""
  DRIFT_DETECTED=1
fi

# Check each critical package
for pkg in "${CRITICAL_PACKAGES[@]}"; do
  if ! command -v "$pkg" &>/dev/null; then
    echo "⚠️  Package not found: $pkg"
    continue
  fi

  PKG_PATH=$(which "$pkg")
  EXPECTED_PREFIX="/run/current-system/sw/bin"

  if [[ "$PKG_PATH" != "$EXPECTED_PREFIX/$pkg" ]]; then
    echo "❌ Version drift detected: $pkg"
    echo "   Expected: $EXPECTED_PREFIX/$pkg"
    echo "   Actual:   $PKG_PATH"
    echo ""
    DRIFT_DETECTED=1
  else
    echo "✅ $pkg: OK"
  fi
done

if [[ $DRIFT_DETECTED -eq 0 ]]; then
  echo ""
  echo "✅ No drift detected - system is consistent"
  exit 0
else
  echo ""
  echo "❌ Drift detected - system requires attention"
  echo ""
  echo "To fix activation mismatch, run:"
  echo "  sudo /nix/var/nix/profiles/system/activate"
  echo ""
  exit 1
fi
