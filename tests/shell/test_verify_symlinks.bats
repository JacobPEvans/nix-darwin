#!/usr/bin/env bats
# Test verify-symlinks.sh for symlink validation

SCRIPT_UNDER_TEST="$BATS_TEST_DIR/../../scripts/workflows/verify-symlinks.sh"

setup() {
  # Create temporary test directory structure
  TEST_HOME_FILES=$(mktemp -d)
  mkdir -p "$TEST_HOME_FILES/.claude/commands"
  mkdir -p "$TEST_HOME_FILES/.claude/agents"

  # Create dummy target files for symlinks
  mkdir -p "$TEST_HOME_FILES/targets"
  echo "dummy" > "$TEST_HOME_FILES/targets/plan-product.md"
  echo "dummy" > "$TEST_HOME_FILES/targets/product-planner.md"
}

teardown() {
  # Clean up temporary directory
  rm -rf "$TEST_HOME_FILES"
}

@test "verify-symlinks.sh: detects valid command symlinks" {
  # Create valid symlink
  ln -s "../../targets/plan-product.md" "$TEST_HOME_FILES/.claude/commands/plan-product.md"

  run bash "$SCRIPT_UNDER_TEST" "$TEST_HOME_FILES"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "✓ plan-product.md" ]]
}

@test "verify-symlinks.sh: detects broken command symlinks" {
  # Create broken symlink
  ln -s "/nonexistent/path.md" "$TEST_HOME_FILES/.claude/commands/plan-product.md"

  run bash "$SCRIPT_UNDER_TEST" "$TEST_HOME_FILES"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "✗ plan-product.md symlink broken" ]]
  [[ "$output" =~ "Found 1 errors" ]]
}

@test "verify-symlinks.sh: detects valid agent symlinks" {
  # Create valid symlink
  ln -s "../../targets/product-planner.md" "$TEST_HOME_FILES/.claude/agents/product-planner.md"

  run bash "$SCRIPT_UNDER_TEST" "$TEST_HOME_FILES"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "✓ product-planner.md" ]]
}

@test "verify-symlinks.sh: validates settings.json" {
  # Create valid JSON file
  echo '{"key": "value"}' > "$TEST_HOME_FILES/.claude/settings.json"

  run bash "$SCRIPT_UNDER_TEST" "$TEST_HOME_FILES"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "✓ settings.json valid" ]]
}

@test "verify-symlinks.sh: detects invalid JSON in settings.json" {
  # Create invalid JSON file
  echo '{"key": "value"' > "$TEST_HOME_FILES/.claude/settings.json"

  run bash "$SCRIPT_UNDER_TEST" "$TEST_HOME_FILES"
  [ "$status" -eq 1 ]
}

@test "verify-symlinks.sh: detects missing settings.json" {
  # Don't create settings.json

  run bash "$SCRIPT_UNDER_TEST" "$TEST_HOME_FILES"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "✗ settings.json not found" ]]
}
