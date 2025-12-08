#!/usr/bin/env bash
# Build home-manager configuration with error detection
# Usage: ./scripts/workflows/build-hm.sh [OUTPUT_LINK]
# Exit codes: 0=success, 1=build failed or error detected

set -euo pipefail

OUTPUT_LINK="${1:-result-hm}"
BUILD_OUTPUT=$(mktemp)
trap 'rm -f "$BUILD_OUTPUT"' EXIT

# Build and capture output
nix build .#ci.hmActivationPackage -o "$OUTPUT_LINK" 2>&1 | tee "$BUILD_OUTPUT"
build_exit_code=${PIPESTATUS[0]}

if [ "$build_exit_code" -ne 0 ]; then
  echo "::error::nix build failed with exit code $build_exit_code"
  exit $build_exit_code
fi

# Fail on actual errors (warnings like builtins.toFile are informational)
if grep -qE "^error:" "$BUILD_OUTPUT"; then
  matched_line=$(grep -E "^error:" "$BUILD_OUTPUT" | head -1)
  echo "::error::Build error detected: $matched_line"
  exit 1
fi

echo "Build completed successfully: $OUTPUT_LINK"
