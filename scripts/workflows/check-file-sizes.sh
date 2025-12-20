#!/usr/bin/env bash
# Check file sizes against tier limits (bytes as token proxy)
# Usage: ./scripts/workflows/check-file-sizes.sh [EXTENDED_LIST] [EXEMPT_LIST]
#
# If no arguments provided, reads from file-size-config.sh
#
# Limits: 6KB recommended, 12KB hard, 32KB extended
#
# Exit codes:
#   0 - All files within limits
#   N - Number of files exceeding their tier limit

set -euo pipefail

# Load config from shared file if no args provided
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ $# -eq 0 ]] && [[ -f "$SCRIPT_DIR/file-size-config.sh" ]]; then
  # shellcheck source=file-size-config.sh
  source "$SCRIPT_DIR/file-size-config.sh"
  EXTENDED="${FILE_SIZE_EXTENDED:-}"
  EXEMPT="${FILE_SIZE_EXEMPT:-}"
else
  EXTENDED="${1:-}"
  EXEMPT="${2:-}"
fi
ERRORS=0

for f in $(find . \( -name "*.md" -o -name "*.nix" \) -not -path "./.git/*" | sort); do
  # Skip symlinks (they point to files that are already checked)
  if [ -L "$f" ]; then continue; fi

  base=$(basename "$f" | sed 's/\.[^.]*$//')
  size=$(wc -c < "$f" | tr -d ' ')
  kb=$((size / 1024))

  # Skip exempt files
  if [[ " $EXEMPT " == *" $base "* ]]; then continue; fi

  # Determine limit and warning threshold
  if [[ " $EXTENDED " == *" $base "* ]]; then
    # Extended files: 32KB limit, no warning
    limit=32768
    warn_threshold=$limit
  else
    # Standard files: 12KB limit, 6KB warning
    limit=12288
    warn_threshold=6144
  fi

  # Report errors and warnings
  if [ "$size" -gt "$limit" ]; then
    echo "::error file=$f::$f is ${kb}KB (exceeds $((limit/1024))KB limit)"
    ERRORS=$((ERRORS + 1))
  elif [ "$size" -gt "$warn_threshold" ]; then
    echo "::warning file=$f::$f is ${kb}KB (exceeds $((warn_threshold/1024))KB recommended)"
  fi
done

exit $ERRORS
