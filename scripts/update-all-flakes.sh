#!/usr/bin/env bash
# Update all flake inputs across the entire repository
#
# Usage: ./scripts/update-all-flakes.sh [--verbose] [--inputs "input1 input2 ..."]
#
# Dynamically discovers ALL flake.nix files in the repository and updates them.
# The root flake is updated first, then all sub-flakes are updated in sorted order.
#
# Options:
#   --verbose                Show full nix flake update output
#   --inputs "i1 i2 ..."    Selective root update (only specified inputs);
#                            sub-flakes still get full updates
#
# Exit codes:
#   0 - Success (flakes updated or already up to date)
#   1 - Error during update

set -euo pipefail

VERBOSE=false
SELECTIVE_INPUTS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --inputs)
      SELECTIVE_INPUTS="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

run_update() {
  local dir="$1"
  if [[ "$VERBOSE" == "true" ]]; then
    (cd "$dir" && nix flake update --refresh) || true
  else
    (cd "$dir" && nix flake update --refresh 2>&1 | tail -5) || true
  fi
}

# Update root flake first
if [[ -n "$SELECTIVE_INPUTS" ]]; then
  echo "=== Updating ROOT flake (selective inputs) ==="
  read -ra INPUTS_ARRAY <<< "$SELECTIVE_INPUTS"
  if [[ "$VERBOSE" == "true" ]]; then
    nix flake update "${INPUTS_ARRAY[@]}"
  else
    nix flake update "${INPUTS_ARRAY[@]}" 2>&1 | tail -10
  fi
else
  echo "=== Updating ROOT flake ==="
  if [[ "$VERBOSE" == "true" ]]; then
    nix flake update --refresh
  else
    nix flake update --refresh 2>&1 | tail -10
  fi
fi

# Discover and update ALL sub-flakes dynamically
echo ""
echo "=== Updating SUB-FLAKES ==="
while IFS= read -r flake_nix; do
  dir="$(dirname "$flake_nix")"
  [[ "$dir" == "." ]] && continue  # skip root (already updated)
  echo "Updating: $dir/"
  run_update "$dir"
done < <(find . -name 'flake.nix' -not -path './.git/*' | sort)

echo ""
echo "=== Update complete ==="
