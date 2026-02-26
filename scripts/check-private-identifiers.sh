#!/usr/bin/env bash
# check-private-identifiers.sh - Pre-commit hook to prevent private identifiers in public repo
#
# Scans staged files for patterns that should never appear in a public repository.
# Patterns are SOPS-encrypted in private-patterns.sops.json (committed safely).
# Requires: sops, jq, age key at ~/.config/sops/age/keys.txt

set -euo pipefail

SOPS_FILE="private-patterns.sops.json"

if [[ ! -f "$SOPS_FILE" ]]; then
  echo "WARNING: $SOPS_FILE not found, skipping private identifier check"
  exit 0
fi

if ! command -v sops &>/dev/null; then
  echo "WARNING: sops not found, skipping private identifier check"
  exit 0
fi

# Decrypt patterns from SOPS at runtime
patterns_json=$(sops --decrypt "$SOPS_FILE" 2>/dev/null) || {
  echo "WARNING: Failed to decrypt $SOPS_FILE (missing age key?), skipping"
  exit 0
}

# Extract patterns array
mapfile -t patterns < <(echo "$patterns_json" | jq -r '.patterns[]')

if (( ${#patterns[@]} == 0 )); then
  exit 0
fi

found=0
while (( "$#" )); do
  file="$1"
  shift

  # Skip the SOPS file itself and this script
  [[ "$file" == "$SOPS_FILE" ]] && continue
  [[ "$file" == "scripts/check-private-identifiers.sh" ]] && continue

  i=0
  while (( i < ${#patterns[@]} )); do
    pattern="${patterns[i]}"
    i=$((i + 1))

    output=$(grep -niE -- "$pattern" "$file" 2>&1) && {
      echo "ERROR: Private identifier found in: $file"
      echo "$output" | head -3 | sed 's/^/  /'
      found=1
      continue
    }
    grep_exit=$?
    if (( grep_exit == 2 )); then
      echo "ERROR: Invalid regex pattern '${pattern}'" >&2
      exit 2
    fi
  done
done

if (( found )); then
  echo ""
  echo "Private identifiers must not be committed to this public repo."
  echo "Manage patterns: sops private-patterns.sops.json"
  exit 1
fi
