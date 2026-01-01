#!/usr/bin/env bats
# Basic BATS framework functionality tests

@test "BATS assertion true" {
  [ 1 -eq 1 ]
}

@test "BATS assertion false detection" {
  run [ 1 -eq 2 ]
  [ "$status" -ne 0 ]
}

@test "BATS can capture output" {
  run echo "hello"
  [ "$status" -eq 0 ]
  [[ "$output" == "hello" ]]
}

@test "BATS handles numeric comparisons" {
  VALUE=42
  [ "$VALUE" -gt 40 ]
  [ "$VALUE" -lt 50 ]
  [ "$VALUE" -eq 42 ]
}
