#!/usr/bin/env bash
# Check file sizes against tier limits (bytes as token proxy)
# Usage: ./scripts/workflows/check-file-sizes.sh [EXTENDED_LIST] [EXEMPT_LIST]
#
# Limits: 8KB recommended, 16KB hard, 32KB extended
#
# Exit codes:
#   0 - All files within limits
#   N - Number of files exceeding their tier limit

set -euo pipefail

EXTENDED="${1:-}"
EXEMPT="${2:-}"
ERRORS=0

for f in $(find . \( -name "*.md" -o -name "*.nix" \) -not -path "./.git/*" | sort); do
  base=$(basename "$f" | sed 's/\.[^.]*$//')
  size=$(wc -c < "$f" | tr -d ' ')
  kb=$((size / 1024))

  # Skip exempt files
  if [[ " $EXEMPT " == *" $base "* ]]; then continue; fi

  # Determine limit: extended (32KB) or standard (16KB)
  if [[ " $EXTENDED " == *" $base "* ]]; then
    limit=32768
  else
    limit=16384
  fi

  # Report errors and warnings
  if [ "$size" -gt "$limit" ]; then
    echo "::error file=$f::$f is ${kb}KB (exceeds $((limit/1024))KB limit)"
    ERRORS=$((ERRORS + 1))
  elif [ "$size" -gt 8192 ]; then
    echo "::warning file=$f::$f is ${kb}KB (exceeds 8KB recommended)"
  fi
done

exit $ERRORS
