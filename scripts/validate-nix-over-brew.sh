#!/usr/bin/env bash
# HARD FAIL if any homebrew packages/casks are available in nixpkgs
# Enforces: nixpkgs FIRST, homebrew as fallback ONLY

set -euo pipefail

# Known false positives: Same name, different apps
# Format: "package-name:reason"
EXCLUSIONS=(
  "shortwave:Different apps - nixpkgs=radio client, homebrew=email client"
)

HOMEBREW_FILE="modules/darwin/homebrew.nix"

if [[ ! -f "$HOMEBREW_FILE" ]]; then
  echo "ERROR: $HOMEBREW_FILE not found"
  exit 1
fi

# Extract brew packages (brews = [...])
brews=$(grep -A 50 'brews = \[' "$HOMEBREW_FILE" | grep '"' | sed 's/.*"\([^"]*\)".*/\1/' || true)

# Extract cask packages (casks = [...])
casks=$(grep -A 50 'casks = \[' "$HOMEBREW_FILE" | grep '"' | sed 's/.*"\([^"]*\)".*/\1/' || true)

if [[ -z "$brews" ]] && [[ -z "$casks" ]]; then
  echo "No homebrew packages to validate"
  exit 0
fi

echo "Checking if homebrew packages are available in nixpkgs..."
failed=0
violations=""

# Check if package is in exclusion list
is_excluded() {
  local pkg="$1"
  for exclusion in "${EXCLUSIONS[@]}"; do
    if [[ "$exclusion" == "$pkg:"* ]]; then
      return 0
    fi
  done
  return 1
}

# Get exclusion reason
get_exclusion_reason() {
  local pkg="$1"
  for exclusion in "${EXCLUSIONS[@]}"; do
    if [[ "$exclusion" == "$pkg:"* ]]; then
      echo "${exclusion#*:}"
      return
    fi
  done
}

# Check brews
while IFS= read -r package; do
  [[ -z "$package" ]] && continue

  # Check if excluded
  if is_excluded "$package"; then
    reason=$(get_exclusion_reason "$package")
    echo "⊘ SKIP: '$package' (brew) - $reason"
    continue
  fi

  # Search nixpkgs (suppress warnings to stderr, check if any results)
  if nix search nixpkgs "^${package}$" 2>/dev/null | grep -q "legacyPackages"; then
    echo "✗ VIOLATION: '$package' (brew) is available in nixpkgs - use nixpkgs instead"
    violations+="  - $package (brew)\n"
    ((failed++))
  else
    echo "✓ OK: '$package' (brew) not in nixpkgs"
  fi
done <<< "$brews"

# Check casks
while IFS= read -r package; do
  [[ -z "$package" ]] && continue

  # Check if excluded
  if is_excluded "$package"; then
    reason=$(get_exclusion_reason "$package")
    echo "⊘ SKIP: '$package' (cask) - $reason"
    continue
  fi

  # Search nixpkgs (suppress warnings to stderr, check if any results)
  if nix search nixpkgs "^${package}$" 2>/dev/null | grep -q "legacyPackages"; then
    echo "✗ VIOLATION: '$package' (cask) is available in nixpkgs - use nixpkgs instead"
    violations+="  - $package (cask)\n"
    ((failed++))
  else
    echo "✓ OK: '$package' (cask) not in nixpkgs"
  fi
done <<< "$casks"

if [[ $failed -gt 0 ]]; then
  echo ""
  echo "=========================================="
  echo "PACKAGE HIERARCHY VIOLATION"
  echo "=========================================="
  echo ""
  echo "The following homebrew packages are available in nixpkgs:"
  echo -e "$violations"
  echo "REQUIRED ACTION:"
  echo "1. Remove package from modules/darwin/homebrew.nix"
  echo "2. Add package to appropriate nixpkgs module"
  echo "   - System: modules/common/packages.nix"
  echo "   - User: modules/home-manager/*/packages.nix"
  echo ""
  echo "Package hierarchy (STRICT): nixpkgs → homebrew → bun → npm → bunx"
  exit 1
fi

echo "All homebrew packages validated - no nixpkgs alternatives available"
