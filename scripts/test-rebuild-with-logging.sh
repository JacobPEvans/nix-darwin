#!/usr/bin/env bash
# Test Rebuild with Full Logging
#
# This script runs darwin-rebuild switch with comprehensive logging
# to help debug the /run/current-system symlink issue.
#
# Usage: sudo ./scripts/test-rebuild-with-logging.sh

set -euo pipefail

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root (use sudo)"
  exit 1
fi

# Create log directory
LOG_DIR="/tmp/darwin-rebuild-debug"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/rebuild-${TIMESTAMP}.log"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Darwin Rebuild Debug Session"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Timestamp: $TIMESTAMP"
echo "Log file: $LOG_FILE"
echo ""

# Capture pre-rebuild state
echo "=== PRE-REBUILD STATE ===" | tee -a "$LOG_FILE"
{
  echo "Current time: $(date)"
  echo "Current /run/current-system: $(readlink /run/current-system)"
  echo "Current generation: $(readlink /nix/var/nix/profiles/system)"
  echo "/run ownership: $(stat -f "%Su:%Sg %Sp" /run)"
  echo "/run/current-system ownership: $(stat -f "%Su:%Sg %Sp" /run/current-system)"
  echo ""
} | tee -a "$LOG_FILE"

# Run darwin-rebuild with full output capture
echo "=== RUNNING DARWIN-REBUILD ===" | tee -a "$LOG_FILE"
echo "Starting rebuild at $(date)..." | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Run with both stdout and stderr captured
if darwin-rebuild switch --flake ~/.config/nix 2>&1 | tee -a "$LOG_FILE"; then
  REBUILD_STATUS="SUCCESS"
else
  REBUILD_STATUS="FAILED"
fi

echo "" | tee -a "$LOG_FILE"
echo "Rebuild completed at $(date) with status: $REBUILD_STATUS" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Capture post-rebuild state
echo "=== POST-REBUILD STATE ===" | tee -a "$LOG_FILE"
{
  echo "Current time: $(date)"
  echo "Current /run/current-system: $(readlink /run/current-system)"
  echo "Current /run/current-system (resolved): $(readlink -f /run/current-system)"
  echo "Current generation: $(readlink /nix/var/nix/profiles/system)"
  echo "Current generation (resolved): $(readlink -f /nix/var/nix/profiles/system)"
  echo ""

  # Check if they match
  CURRENT=$(readlink -f /run/current-system)
  EXPECTED=$(readlink -f /nix/var/nix/profiles/system)

  if [ "$CURRENT" = "$EXPECTED" ]; then
    echo "✅ SYNCHRONIZED: /run/current-system matches latest generation"
  else
    echo "❌ OUT OF SYNC:"
    echo "   Current:  $CURRENT"
    echo "   Expected: $EXPECTED"
  fi
  echo ""
} | tee -a "$LOG_FILE"

# Analyze the log
echo "=== ANALYSIS ===" | tee -a "$LOG_FILE"
{
  echo "Searching for DEBUG markers in log..."
  if grep -q "\[DEBUG\]" "$LOG_FILE"; then
    echo "✅ Found DEBUG output"
    echo ""
    echo "DEBUG lines:"
    grep "\[DEBUG\]" "$LOG_FILE" | head -20
  else
    echo "❌ No DEBUG output found (debugging may not be enabled)"
  fi
  echo ""

  echo "Searching for activation warnings..."
  if grep -q "WARNING.*Activation verification" "$LOG_FILE"; then
    echo "⚠️  Found activation verification warnings"
  else
    echo "✅ No activation warnings"
  fi
  echo ""
} | tee -a "$LOG_FILE"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Rebuild complete!"
echo ""
echo "Full log saved to: $LOG_FILE"
echo ""
echo "To analyze:"
echo "  cat $LOG_FILE"
echo "  grep DEBUG $LOG_FILE"
echo "  grep -i error $LOG_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
