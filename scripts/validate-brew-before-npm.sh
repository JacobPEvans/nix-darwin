#!/usr/bin/env bash
# HARD FAIL if any npm/npx/bunx packages are available in homebrew
# This enforces the package hierarchy: nixpkgs -> homebrew -> bun -> npm -> bunx

set -euo pipefail

# Check if brew is available
if ! command -v brew &> /dev/null; then
  echo "ERROR: brew is required but not installed"
  exit 1
fi

AI_TOOLS_FILE="modules/home-manager/ai-cli/ai-tools.nix"

if [[ ! -f "$AI_TOOLS_FILE" ]]; then
  echo "ERROR: $AI_TOOLS_FILE not found"
  exit 1
fi

# Extract package names from bunx wrappers (without @version, preserving @scope)
# Match: bunx --bun PACKAGE@version or bunx --bun @scope/PACKAGE@version
# Uses explicit character classes (A-Za-z0-9._-) consistent with validate-npm-urls.sh
packages=$(grep -oE 'bunx --bun[[:space:]]+(@[A-Za-z0-9._-]+/[A-Za-z0-9._-]+|[A-Za-z0-9._-]+)@' "$AI_TOOLS_FILE" | sed -E 's/^bunx --bun[[:space:]]+//; s/@$//' || true)

if [[ -z "$packages" ]]; then
  echo "No npm packages to validate against homebrew"
  exit 0
fi

echo "Checking if npm packages are available in homebrew..."
failed=0
violations=""

while IFS= read -r package; do
  # For scoped packages (@scope/name), check Homebrew with the package name part only
  # Homebrew doesn't use @scope syntax, so @scope/name should be checked as "name"
  if [[ "$package" == @*/* ]]; then
    brew_name="${package#@*/}"
  else
    brew_name="$package"
  fi

  # Check if package exists in homebrew (using -Fx for exact fixed-string match)
  if brew search "$brew_name" 2>/dev/null | grep -qFx -- "$brew_name"; then
    echo "✗ VIOLATION: '$package' is available in homebrew - use homebrew instead of bunx"
    violations+="  - $package\n"
    ((failed++))
  else
    echo "✓ OK: '$package' not in homebrew (bunx is appropriate)"
  fi
done <<< "$packages"

if [[ $failed -gt 0 ]]; then
  echo ""
  echo "=========================================="
  echo "PACKAGE HIERARCHY VIOLATION"
  echo "=========================================="
  echo ""
  echo "The following packages are available in homebrew but defined as npm packages:"
  echo -e "$violations"
  echo "REQUIRED ACTION:"
  echo "1. Add package to modules/darwin/homebrew.nix (brews section)"
  echo "2. Remove bunx wrapper from $AI_TOOLS_FILE"
  echo "3. Add comment documenting why homebrew is used"
  echo ""
  echo "Package hierarchy (STRICT): nixpkgs → homebrew → bun → npm → bunx"
  exit 1
fi

echo "All npm packages validated - no homebrew alternatives available"
