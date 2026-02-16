#!/usr/bin/env bash
# Determine which flake inputs to update based on trigger context
#
# Called by: .github/workflows/deps-update-flake.yml
#
# Required environment variables (set by workflow):
#   EVENT_NAME       - GitHub event name (schedule, repository_dispatch, etc.)
#   UPDATE_ALL       - Whether to update all inputs (from workflow_dispatch)
#   DISPATCH_ACTION  - repository_dispatch action type
#   FLAKE_INPUT_NAME - Specific input name from client_payload
#   SOURCE_REPO      - Source repo from client_payload
#   AI_INPUTS        - Space-separated list of allowed AI-focused inputs
#   GITHUB_OUTPUT    - GitHub Actions output file
#
# Outputs (via GITHUB_OUTPUT):
#   inputs - Space-separated list of inputs to update (empty = all)

set -euo pipefail

if [[ "$EVENT_NAME" == "repository_dispatch" ]]; then
  case "$DISPATCH_ACTION" in
    ai-instructions-updated)
      echo "inputs=ai-assistant-instructions" >> "$GITHUB_OUTPUT"
      echo "::notice::Fast sync: updating ai-assistant-instructions only"
      ;;
    upstream-repo-updated)
      if [[ -z "$FLAKE_INPUT_NAME" ]]; then
        echo "::error::flake_input_name not provided in client_payload"
        exit 1
      fi
      if [[ ! "$FLAKE_INPUT_NAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "::error::Invalid flake_input_name '$FLAKE_INPUT_NAME'; only [a-zA-Z0-9._-] are allowed"
        exit 1
      fi
      if ! grep -Eq "(^|[[:space:]])$FLAKE_INPUT_NAME([[:space:]]|$)" <<< "$AI_INPUTS"; then
        echo "::error::flake_input_name '$FLAKE_INPUT_NAME' is not in the allowed inputs list"
        exit 1
      fi
      echo "inputs=$FLAKE_INPUT_NAME" >> "$GITHUB_OUTPUT"
      echo "::notice::Fast sync: updating $FLAKE_INPUT_NAME from $SOURCE_REPO"
      ;;
    *)
      echo "::error::Unknown dispatch type: $DISPATCH_ACTION"
      exit 1
      ;;
  esac
elif [[ "$(date -u +%u)" == "2" || "$(date -u +%u)" == "5" || "$UPDATE_ALL" == "true" ]]; then
  echo "inputs=" >> "$GITHUB_OUTPUT"
  echo "::notice::Updating ALL flake inputs"
else
  echo "inputs=$AI_INPUTS" >> "$GITHUB_OUTPUT"
  echo "::notice::Updating AI-focused inputs only"
fi
