#!/usr/bin/env bats
# Test compare_versions function from check-package-versions.sh

SCRIPT_UNDER_TEST="$BATS_TEST_DIRNAME/../../scripts/workflows/check-package-versions.sh"

setup() {
  # Extract only the compare_versions function definition to avoid sourcing
  # top-level code that requires jq, nix, and network access
  FUNC_FILE=$(mktemp)
  awk '/^compare_versions\(\)/,/^\}$/' "$SCRIPT_UNDER_TEST" > "$FUNC_FILE"
}

teardown() {
  rm -f "$FUNC_FILE"
}

@test "compare_versions: equal versions are current (exit 0)" {
  run bash -c "source '$FUNC_FILE'; compare_versions '1.2.3' '1.2.3'"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Current" ]]
}

@test "compare_versions: major version bump is detected (exit 3)" {
  run bash -c "source '$FUNC_FILE'; compare_versions '1.0.0' '2.0.0'"
  [ "$status" -eq 3 ]
  [[ "$output" =~ "Major" ]]
}

@test "compare_versions: minor version bump is detected (exit 1)" {
  run bash -c "source '$FUNC_FILE'; compare_versions '1.0.0' '1.1.0'"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Minor" ]]
}

@test "compare_versions: patch version bump is detected (exit 1)" {
  run bash -c "source '$FUNC_FILE'; compare_versions '1.2.0' '1.2.1'"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Patch" ]]
}

@test "compare_versions: unknown current version returns unknown (exit 2)" {
  run bash -c "source '$FUNC_FILE'; compare_versions 'unknown' '1.0.0'"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Unknown" ]]
}

@test "compare_versions: unknown latest version returns unknown (exit 2)" {
  run bash -c "source '$FUNC_FILE'; compare_versions '1.0.0' 'unknown'"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Unknown" ]]
}

@test "compare_versions: both unknown returns unknown (exit 2)" {
  run bash -c "source '$FUNC_FILE'; compare_versions 'unknown' 'unknown'"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Unknown" ]]
}

@test "check-package-versions.sh: exits with error when jq/nix are missing" {
  EMPTY_BIN=$(mktemp -d)
  run env PATH="$EMPTY_BIN" bash "$SCRIPT_UNDER_TEST"
  rm -rf "$EMPTY_BIN"
  [ "$status" -eq 1 ]
}
