#!/usr/bin/env bash
# Validate Package Freshness - Pre-commit Hook
#
# PURPOSE: Prevent committing flake.lock with outdated package versions
# FAIL THRESHOLDS:
#   - Critical packages (nixpkgs, darwin, home-manager): >30 days = FAIL
#   - All packages: >90 days = FAIL
# EXEMPTIONS: Packages in EXEMPT_PACKAGES array skip age checks
#
# USAGE: Run as pre-commit hook or manually: ./scripts/validate-package-freshness.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Configuration
CRITICAL_THRESHOLD_DAYS=30
GENERAL_THRESHOLD_DAYS=90
FLAKE_LOCK="flake.lock"

# Critical packages that must be <30 days old
CRITICAL_PACKAGES=(
  "nixpkgs"
  "darwin"
  "home-manager"
  "ai-assistant-instructions"
  "llm-agents"
)

# Exempt packages (archived repos, intentional pins)
# Add packages here that should never trigger staleness failures
# Supports glob patterns: "prefix*" matches "prefix", "prefix_2", etc.
EXEMPT_PACKAGES=(
  "flake-compat"  # Compatibility shim - stable interface, infrequent updates needed
  "flake-utils"   # Utility library - stable helpers, infrequent updates needed
  "systems"       # nix-systems/default-darwin - system architectures, rarely updated
)

# Check if flake.lock exists
if [[ ! -f "$FLAKE_LOCK" ]]; then
  echo -e "${YELLOW}⚠  No flake.lock found, skipping freshness check${NC}"
  exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
  echo -e "${RED}✗ ERROR: jq is required but not installed${NC}"
  echo "Install: nix-shell -p jq or brew install jq"
  exit 1
fi

# Function: Extract lastModified timestamp from flake.lock
get_last_modified() {
  local package=$1
  jq -r ".nodes.\"$package\".locked.lastModified // 0" "$FLAKE_LOCK"
}

# Function: Check if package matches any exemption pattern (supports globs)
is_in_array() {
  local element=$1
  shift
  local array=("$@")
  for pattern in "${array[@]}"; do
    # Use glob pattern matching (supports wildcards)
    [[ "$element" == $pattern ]] && return 0
  done
  return 1
}

# Main validation loop
FAILED=0
WARNINGS=0
CURRENT_TIME=$(date +%s)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Package Freshness Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check critical packages first
echo "Checking CRITICAL packages (must be <$CRITICAL_THRESHOLD_DAYS days):"
for package in "${CRITICAL_PACKAGES[@]}"; do
  # Check if package exists in flake.lock
  if ! jq -e ".nodes.\"$package\"" "$FLAKE_LOCK" &> /dev/null; then
    echo -e "  ${YELLOW}⊘ SKIP${NC}: $package (not in flake.lock)"
    continue
  fi

  LAST_MOD=$(get_last_modified "$package")

  if [[ "$LAST_MOD" == "0" ]]; then
    echo -e "  ${YELLOW}⚠  WARN${NC}: $package (no lastModified field)"
    ((WARNINGS++))
    continue
  fi

  DAYS_OLD=$(( (CURRENT_TIME - LAST_MOD) / 86400 ))

  if [[ $DAYS_OLD -gt $CRITICAL_THRESHOLD_DAYS ]]; then
    echo -e "  ${RED}✗ FAIL${NC}: $package is ${RED}$DAYS_OLD days${NC} old (threshold: $CRITICAL_THRESHOLD_DAYS days)"
    ((FAILED++))
  else
    echo -e "  ${GREEN}✓ OK${NC}:   $package ($DAYS_OLD days old)"
  fi
done

echo ""
echo "Checking ALL packages (must be <$GENERAL_THRESHOLD_DAYS days):"

# Get all package names from flake.lock
mapfile -t ALL_PACKAGES < <(jq -r '.nodes | keys[]' "$FLAKE_LOCK")

for package in "${ALL_PACKAGES[@]}"; do
  # Skip root node
  [[ "$package" == "root" ]] && continue

  # Skip if already checked in critical packages
  if is_in_array "$package" "${CRITICAL_PACKAGES[@]}"; then
    continue
  fi

  # Skip if in exempt list
  if is_in_array "$package" "${EXEMPT_PACKAGES[@]}"; then
    echo -e "  ${YELLOW}⊘ EXEMPT${NC}: $package (in exemption list)"
    continue
  fi

  LAST_MOD=$(get_last_modified "$package")

  if [[ "$LAST_MOD" == "0" ]]; then
    # No lastModified field (might be a flake input that follows another)
    continue
  fi

  DAYS_OLD=$(( (CURRENT_TIME - LAST_MOD) / 86400 ))

  if [[ $DAYS_OLD -gt $GENERAL_THRESHOLD_DAYS ]]; then
    echo -e "  ${RED}✗ FAIL${NC}: $package is ${RED}$DAYS_OLD days${NC} old (threshold: $GENERAL_THRESHOLD_DAYS days)"
    ((FAILED++))
  elif [[ $DAYS_OLD -gt 60 ]]; then
    # Warn if approaching threshold
    echo -e "  ${YELLOW}⚠  WARN${NC}: $package is $DAYS_OLD days old (approaching threshold)"
    ((WARNINGS++))
  else
    echo -e "  ${GREEN}✓ OK${NC}:   $package ($DAYS_OLD days old)"
  fi
done

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $FAILED -gt 0 ]]; then
  echo -e "${RED}✗ VALIDATION FAILED${NC}: $FAILED package(s) exceed staleness threshold"
  echo ""
  echo "To fix outdated packages:"
  echo "  1. Update flake inputs: nix flake update"
  echo "  2. Or update specific input: nix flake lock --update-input <package>"
  echo "  3. Review changes: nix flake metadata"
  echo "  4. Test rebuild: darwin-rebuild switch --flake ."
  echo ""
  echo "To exempt a package (intentional pin):"
  echo "  Add to EXEMPT_PACKAGES array in scripts/validate-package-freshness.sh"
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  echo -e "${YELLOW}⚠  PASSED WITH WARNINGS${NC}: $WARNINGS package(s) approaching threshold"
  exit 0
else
  echo -e "${GREEN}✓ ALL PACKAGES FRESH${NC}: All packages within acceptable age ranges"
  exit 0
fi
