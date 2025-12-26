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

echo "=== System Drift Monitor ===" >&2
echo "Date: $(date)" >&2
echo "" >&2

DRIFT_DETECTED=0

# Check activation state first
SYSTEM_PROFILE_TARGET=$(readlink -f /nix/var/nix/profiles/system)
CURRENT_SYSTEM=$(readlink -f /run/current-system)

if [[ "$SYSTEM_PROFILE_TARGET" != "$CURRENT_SYSTEM" ]]; then
  echo "❌ CRITICAL: Activation mismatch detected" >&2
  echo "   System profile: $SYSTEM_PROFILE_TARGET" >&2
  echo "   Current system: $CURRENT_SYSTEM" >&2
  echo "" >&2
  DRIFT_DETECTED=1
fi

# Check each critical package
# Note: Using while read with process substitution instead of for loop
# to comply with repository rules and avoid permission matching issues
while IFS= read -r pkg; do
  if ! command -v "$pkg" &>/dev/null; then
    echo "⚠️  Package not found: $pkg" >&2
    continue
  fi

  PKG_PATH=$(which "$pkg")
  EXPECTED_PREFIX="/run/current-system/sw/bin"

  if [[ "$PKG_PATH" != "$EXPECTED_PREFIX/$pkg" ]]; then
    echo "❌ Version drift detected: $pkg" >&2
    echo "   Expected: $EXPECTED_PREFIX/$pkg" >&2
    echo "   Actual:   $PKG_PATH" >&2
    echo "" >&2
    DRIFT_DETECTED=1
  else
    echo "✅ $pkg: OK" >&2
  fi
done < <(printf "%s\n" "${CRITICAL_PACKAGES[@]}")

if [[ $DRIFT_DETECTED -eq 0 ]]; then
  echo "" >&2
  echo "✅ No drift detected - system is consistent" >&2
  exit 0
else
  echo "" >&2
  echo "❌ Drift detected - system requires attention" >&2
  echo "" >&2
  echo "To fix activation mismatch, run:" >&2
  echo "  sudo /nix/var/nix/profiles/system/activate" >&2
  echo "" >&2
  exit 1
fi
