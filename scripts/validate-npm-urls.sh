#!/usr/bin/env bash
# Quick validation of npm package URLs in ai-tools.nix
# Checks that all npm packages referenced actually exist on npmjs.org

set -euo pipefail

# Check if curl is available
if ! command -v curl &> /dev/null; then
  echo "ERROR: curl is required but not installed"
  exit 1
fi

# Extract npm package names from bunx wrappers in ai-tools.nix
# Format: bunx --bun package@version or bunx --bun @scope/package@version
AI_TOOLS_FILE="modules/home-manager/ai-cli/ai-tools.nix"

if [[ ! -f "$AI_TOOLS_FILE" ]]; then
  echo "ERROR: $AI_TOOLS_FILE not found"
  exit 1
fi

# Extract package names (without @version)
# Match: bunx --bun PACKAGE@version or bunx --bun @scope/PACKAGE@version
# Uses explicit character classes and handles whitespace variations
packages=$(grep -oE 'bunx --bun[[:space:]]+(@[a-z0-9._-]+/[a-z0-9._-]+|[a-z0-9._-]+)@' "$AI_TOOLS_FILE" | sed -E 's/^bunx --bun[[:space:]]+//; s/@$//' || true)

if [[ -z "$packages" ]]; then
  echo "No npm packages found to validate"
  exit 0
fi

echo "Validating npm package URLs..."
failed=0

while IFS= read -r package; do
  # Construct npm registry URL
  # Scoped packages: @scope/name -> @scope%2Fname
  url_package="${package/\//%2F}"
  url="https://registry.npmjs.org/${url_package}"

  # Check if URL exists (HTTP 200)
  if ! curl -sf -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
    echo "✗ FAILED: $package ($url returned non-200)"
    ((failed++))
  else
    echo "✓ OK: $package"
  fi
done <<< "$packages"

if [[ $failed -gt 0 ]]; then
  echo ""
  echo "ERROR: $failed package(s) failed validation"
  exit 1
fi

echo "All npm packages validated successfully"
