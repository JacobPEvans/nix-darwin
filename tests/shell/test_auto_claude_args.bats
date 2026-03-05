#!/usr/bin/env bats
# Test auto-claude.sh argument parsing
# NOTE: auto-claude.sh has moved to nix-ai. This test file is retained for
# reference but is excluded from the BATS test run in lib/checks.nix.

# Define script path — this script now lives in nix-ai, not in this repo.
# The path below will not resolve locally; tests are skipped in CI.
SCRIPT_UNDER_TEST="$BATS_TEST_DIRNAME/../../modules/home-manager/ai-cli/claude/auto-claude.sh"

@test "auto-claude.sh: requires 2 arguments" {
  run bash "$SCRIPT_UNDER_TEST"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "auto-claude.sh: rejects non-existent directory" {
  run bash "$SCRIPT_UNDER_TEST" /nonexistent 10.0
  [ "$status" -eq 1 ]
  [[ "$output" =~ "does not exist" ]]
}

@test "auto-claude.sh: rejects invalid budget" {
  TEST_DIR=$(mktemp -d)
  mkdir -p "$TEST_DIR/test"
  run bash "$SCRIPT_UNDER_TEST" "$TEST_DIR/test" "invalid"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "must be a positive number" ]]
  rm -rf "$TEST_DIR"
}
