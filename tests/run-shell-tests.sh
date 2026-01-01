#!/usr/bin/env bash
# Shell script test runner using BATS
# Usage: ./tests/run-shell-tests.sh [test-pattern]

set -euo pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_PATTERN="${1:-*.bats}"

echo "Running shell script tests..."
echo "Test directory: $TEST_DIR"
echo "Pattern: $TEST_PATTERN"
echo ""

if ! command -v bats &>/dev/null; then
  echo "Error: bats not found. Please enter the nix-shell or rebuild your environment to make it available."
  exit 1
fi

bats "$TEST_DIR/shell/$TEST_PATTERN" || EXIT_CODE=$?
exit "${EXIT_CODE:-0}"
