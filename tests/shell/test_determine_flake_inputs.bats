#!/usr/bin/env bats
# Test determine-flake-inputs.sh logic

SCRIPT_UNDER_TEST="$BATS_TEST_DIRNAME/../../scripts/workflows/determine-flake-inputs.sh"

setup() {
  GITHUB_OUTPUT_FILE=$(mktemp)
  export GITHUB_OUTPUT="$GITHUB_OUTPUT_FILE"
  # Initialize all env vars required by set -u in the script
  export EVENT_NAME="schedule"
  export UPDATE_ALL="false"
  export DISPATCH_ACTION=""
  export FLAKE_INPUT_NAME=""
  export SOURCE_REPO=""
  export AI_INPUTS="nix-ai nix-home"
}

teardown() {
  rm -f "$GITHUB_OUTPUT_FILE"
}

@test "determine-flake-inputs.sh: ai-instructions-updated outputs ai-assistant-instructions" {
  export EVENT_NAME="repository_dispatch"
  export DISPATCH_ACTION="ai-instructions-updated"

  run bash "$SCRIPT_UNDER_TEST"
  [ "$status" -eq 0 ]
  grep -q "^inputs=ai-assistant-instructions$" "$GITHUB_OUTPUT_FILE"
  [[ "$output" =~ "ai-assistant-instructions" ]]
}

@test "determine-flake-inputs.sh: upstream-repo-updated outputs specific flake input" {
  export EVENT_NAME="repository_dispatch"
  export DISPATCH_ACTION="upstream-repo-updated"
  export FLAKE_INPUT_NAME="nix-ai"
  export SOURCE_REPO="JacobPEvans/nix-ai"

  run bash "$SCRIPT_UNDER_TEST"
  [ "$status" -eq 0 ]
  grep -q "^inputs=nix-ai$" "$GITHUB_OUTPUT_FILE"
}

@test "determine-flake-inputs.sh: upstream-repo-updated with empty input name fails" {
  export EVENT_NAME="repository_dispatch"
  export DISPATCH_ACTION="upstream-repo-updated"
  export FLAKE_INPUT_NAME=""

  run bash "$SCRIPT_UNDER_TEST"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "flake_input_name not provided" ]]
}

@test "determine-flake-inputs.sh: upstream-repo-updated rejects invalid characters in input name" {
  export EVENT_NAME="repository_dispatch"
  export DISPATCH_ACTION="upstream-repo-updated"
  export FLAKE_INPUT_NAME='nix-ai;rm -rf /'

  run bash "$SCRIPT_UNDER_TEST"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Invalid flake_input_name" ]]
}

@test "determine-flake-inputs.sh: upstream-repo-updated rejects input not in AI_INPUTS" {
  export EVENT_NAME="repository_dispatch"
  export DISPATCH_ACTION="upstream-repo-updated"
  export FLAKE_INPUT_NAME="not-an-allowed-input"

  run bash "$SCRIPT_UNDER_TEST"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "not in the allowed inputs list" ]]
}

@test "determine-flake-inputs.sh: unknown dispatch action fails with error message" {
  export EVENT_NAME="repository_dispatch"
  export DISPATCH_ACTION="unknown-action-type"

  run bash "$SCRIPT_UNDER_TEST"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Unknown dispatch type" ]]
}

@test "determine-flake-inputs.sh: UPDATE_ALL=true triggers full update with empty inputs" {
  export EVENT_NAME="schedule"
  export UPDATE_ALL="true"

  run bash "$SCRIPT_UNDER_TEST"
  [ "$status" -eq 0 ]
  grep -q "^inputs=$" "$GITHUB_OUTPUT_FILE"
  [[ "$output" =~ "Updating ALL flake inputs" ]]
}

@test "determine-flake-inputs.sh: non-dispatch event succeeds and writes inputs to GITHUB_OUTPUT" {
  export EVENT_NAME="schedule"
  export UPDATE_ALL="false"

  run bash "$SCRIPT_UNDER_TEST"
  [ "$status" -eq 0 ]
  # Regardless of day-of-week, the script must write an 'inputs=' line
  grep -q "^inputs=" "$GITHUB_OUTPUT_FILE"
}
