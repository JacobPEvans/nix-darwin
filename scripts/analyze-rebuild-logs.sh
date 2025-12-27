#!/usr/bin/env bash
# Analyze Rebuild Logs
#
# Analyzes captured darwin-rebuild logs to identify why /run/current-system
# symlink is not being updated.
#
# Usage: ./scripts/analyze-rebuild-logs.sh <logfile>

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <logfile>"
  echo ""
  echo "Example:"
  echo "  $0 /tmp/darwin-rebuild-debug/rebuild-*.log"
  exit 1
fi

LOG_FILE="$1"

if [ ! -f "$LOG_FILE" ]; then
  echo "Error: Log file not found: $LOG_FILE"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Log Analysis: $LOG_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Check if DEBUG output is present
echo "1. DEBUG Output Check:"
if grep -q "\[DEBUG\]" "$LOG_FILE"; then
  echo "   ✅ Found DEBUG markers"
  DEBUG_COUNT=$(grep -c "\[DEBUG\]" "$LOG_FILE" || true)
  echo "   Total DEBUG lines: $DEBUG_COUNT"
else
  echo "   ❌ No DEBUG output found"
  echo "   This means debugging may not be enabled in the activate script"
fi
echo ""

# 2. Extract pre/post activation state
echo "2. Activation State:"
if grep -q "PRE-REBUILD STATE" "$LOG_FILE"; then
  echo "   Pre-rebuild /run/current-system:"
  grep -A1 "Current /run/current-system:" "$LOG_FILE" | head -2 | tail -1
fi
if grep -q "POST-REBUILD STATE" "$LOG_FILE"; then
  echo "   Post-rebuild /run/current-system:"
  grep -A1 "POST-REBUILD STATE" "$LOG_FILE" | grep "Current /run/current-system:" | tail -1
fi
echo ""

# 3. Check for errors
echo "3. Error Analysis:"
ERROR_PATTERNS=("ERROR" "error:" "failed" "FAILED" "cannot" "denied" "permission")
FOUND_ERRORS=0
for pattern in "${ERROR_PATTERNS[@]}"; do
  if grep -qi "$pattern" "$LOG_FILE"; then
    COUNT=$(grep -ci "$pattern" "$LOG_FILE" || true)
    if [ "$COUNT" -gt 0 ]; then
      echo "   Found '$pattern': $COUNT occurrence(s)"
      FOUND_ERRORS=1
    fi
  fi
done
if [ $FOUND_ERRORS -eq 0 ]; then
  echo "   ✅ No obvious errors found"
fi
echo ""

# 4. Check activation warnings
echo "4. Activation Warnings:"
if grep -q "WARNING.*Activation verification" "$LOG_FILE"; then
  echo "   ⚠️  Found activation verification warning"
  grep "WARNING.*Activation verification" "$LOG_FILE" -A5 | head -10
else
  echo "   ✅ No activation warnings"
fi
echo ""

# 5. Trace DEBUG flow
echo "5. DEBUG Execution Flow:"
if grep -q "\[DEBUG\]" "$LOG_FILE"; then
  echo "   Activation script execution:"
  grep "\[DEBUG\]" "$LOG_FILE" | head -20
else
  echo "   No DEBUG trace available"
fi
echo ""

# 6. Check for specific markers
echo "6. Key Event Markers:"
MARKERS=(
  "preActivation: Starting"
  "preActivation: Completed"
  "postActivation: Starting"
  "postActivation: Completed"
  "Configuring custom file extension mappings"
  "Successfully registered.*file extension"
)
for marker in "${MARKERS[@]}"; do
  if grep -q "$marker" "$LOG_FILE"; then
    echo "   ✅ Found: $marker"
  else
    echo "   ❌ Missing: $marker"
  fi
done
echo ""

# 7. Check systemConfig values
echo "7. SystemConfig Analysis:"
if grep -q "systemConfig=" "$LOG_FILE"; then
  echo "   Found systemConfig assignments:"
  grep "systemConfig=" "$LOG_FILE" | head -5
else
  echo "   No systemConfig values found in log"
fi
echo ""

# 8. Final verdict
echo "8. Analysis Summary:"
echo ""
PRE_LINK=$(grep "PRE-REBUILD STATE" "$LOG_FILE" -A10 | grep "Current /run/current-system:" | head -1 | awk '{print $NF}' || echo "UNKNOWN")
POST_LINK=$(grep "POST-REBUILD STATE" "$LOG_FILE" -A10 | grep "Current /run/current-system:" | head -1 | awk '{print $NF}' || echo "UNKNOWN")

if [ "$PRE_LINK" = "$POST_LINK" ]; then
  echo "   ❌ ISSUE CONFIRMED: Symlink did not update"
  echo "      Before: $PRE_LINK"
  echo "      After:  $POST_LINK"
  echo ""
  echo "   Possible causes:"
  echo "   - ln -sfn command not executing"
  echo "   - Permission issue preventing symlink update"
  echo "   - Command failing silently"
  echo "   - Symlink being overwritten after update"
else
  echo "   ✅ Symlink updated successfully"
  echo "      Before: $PRE_LINK"
  echo "      After:  $POST_LINK"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "For detailed analysis, search the log for:"
echo "  grep DEBUG $LOG_FILE"
echo "  grep ERROR $LOG_FILE"
echo "  grep -i warning $LOG_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
