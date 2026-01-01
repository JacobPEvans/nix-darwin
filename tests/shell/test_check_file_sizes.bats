#!/usr/bin/env bats
# Test check-file-sizes.sh functionality

SCRIPT_UNDER_TEST="$BATS_TEST_DIR/../../scripts/workflows/check-file-sizes.sh"

setup() {
  # Create temporary test directory
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR" || exit 1
}

teardown() {
  # Clean up temporary directory
  cd /
  rm -rf "$TEST_DIR"
}

@test "check-file-sizes.sh: accepts small files (< 6KB)" {
  # Create 5KB file (5120 bytes)
  head -c 5120 /dev/zero > small.md

  run bash "$SCRIPT_UNDER_TEST" "" ""
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "warning" ]]
  [[ ! "$output" =~ "error" ]]
}

@test "check-file-sizes.sh: warns for medium files (6KB-12KB)" {
  # Create 8KB file (8192 bytes)
  head -c 8192 /dev/zero > medium.md

  run bash "$SCRIPT_UNDER_TEST" "" ""
  [ "$status" -eq 0 ]
  [[ "$output" =~ "::warning" ]]
  [[ "$output" =~ "medium.md" ]]
  [[ "$output" =~ "8KB" ]]
}

@test "check-file-sizes.sh: errors for oversized files (> 12KB)" {
  # Create 16KB file (16384 bytes)
  head -c 16384 /dev/zero > large.md

  run bash "$SCRIPT_UNDER_TEST" "" ""
  [ "$status" -eq 1 ]
  [[ "$output" =~ "::error" ]]
  [[ "$output" =~ "large.md" ]]
  [[ "$output" =~ "16KB" ]]
}

@test "check-file-sizes.sh: extended files allowed up to 32KB" {
  # Create 20KB file (20480 bytes)
  head -c 20480 /dev/zero > extended.md

  # Pass "extended" to EXTENDED_LIST
  run bash "$SCRIPT_UNDER_TEST" "extended" ""
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "::error" ]]
  [[ ! "$output" =~ "::warning" ]]
}

@test "check-file-sizes.sh: extended files error beyond 32KB" {
  # Create 40KB file (40960 bytes)
  head -c 40960 /dev/zero > extended.md

  # Pass "extended" to EXTENDED_LIST
  run bash "$SCRIPT_UNDER_TEST" "extended" ""
  [ "$status" -eq 1 ]
  [[ "$output" =~ "::error" ]]
  [[ "$output" =~ "extended.md" ]]
}

@test "check-file-sizes.sh: exempt files are skipped" {
  # Create 20KB file (20480 bytes)
  head -c 20480 /dev/zero > exempt.md

  # Pass "exempt" to EXEMPT_LIST
  run bash "$SCRIPT_UNDER_TEST" "" "exempt"
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "exempt.md" ]]
}

@test "check-file-sizes.sh: checks both .md and .nix files" {
  # Create oversized .nix file
  head -c 16384 /dev/zero > config.nix

  run bash "$SCRIPT_UNDER_TEST" "" ""
  [ "$status" -eq 1 ]
  [[ "$output" =~ "::error" ]]
  [[ "$output" =~ "config.nix" ]]
}

@test "check-file-sizes.sh: counts multiple errors correctly" {
  # Create three oversized files
  head -c 16384 /dev/zero > file1.md
  head -c 16384 /dev/zero > file2.md
  head -c 16384 /dev/zero > file3.nix

  run bash "$SCRIPT_UNDER_TEST" "" ""
  [ "$status" -eq 3 ]
}
