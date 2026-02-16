#!/usr/bin/env bash
# Update all flake inputs across the entire repository
#
# Usage: ./scripts/update-all-flakes.sh [--verbose] [--inputs "input1 input2 ..."]
#
# Updates:
# - Root flake.lock (darwin, home-manager, nixpkgs, AI tools)
# - Shell environment flakes (shells/**/flake.lock)
# - Host-specific flakes (hosts/**/flake.lock)
#
# Options:
#   --verbose                Show full nix flake update output
#   --inputs "i1 i2 ..."    Selective root update (only specified inputs);
#                            shell/host flakes still get full updates
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

# Update root flake
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

# Update all shell environment flakes
echo ""
echo "=== Updating SHELL flakes ==="
for dir in shells/*/; do
  if [[ -f "${dir}flake.nix" ]]; then
    echo "Updating: $dir"
    if [[ "$VERBOSE" == "true" ]]; then
      (cd "$dir" && nix flake update --refresh) || true
    else
      (cd "$dir" && nix flake update --refresh 2>&1 | tail -3) || true
    fi
  fi
done

# Update host-specific flakes if they have locks
if ls hosts/*/flake.lock 1> /dev/null 2>&1; then
  echo ""
  echo "=== Updating HOST flakes ==="
  for dir in hosts/*/; do
    if [[ -f "${dir}flake.lock" ]]; then
      echo "Updating: $dir"
      if [[ "$VERBOSE" == "true" ]]; then
        (cd "$dir" && nix flake update --refresh) || true
      else
        (cd "$dir" && nix flake update --refresh 2>&1 | tail -3) || true
      fi
    fi
  done
fi

echo ""
echo "=== Update complete ==="
