#!/usr/bin/env bash
# Check if Renovate bot has an open PR modifying flake.lock
#
# Called by: .github/workflows/deps-update-flake.yml
#
# Required environment variables (set by workflow):
#   GH_TOKEN      - GitHub token for API access
#   GITHUB_OUTPUT - GitHub Actions output file
#
# Outputs (via GITHUB_OUTPUT):
#   skip - "true" if Renovate PR exists, "false" otherwise

set -euo pipefail

# SECURITY: Only extracts PR number (integer) from JSON - safe from injection
RENOVATE_PR=$(gh pr list \
  --search "author:app/renovate is:open" \
  --state open \
  --json number,files \
  --jq '[.[] | select(any(.files[].path; . == "flake.lock"))][0].number // ""')

if [[ -n "$RENOVATE_PR" ]]; then
  # SECURITY: RENOVATE_PR is always a number (from --json number field)
  printf "::notice::Renovate PR #%s already exists for flake.lock updates\n" "$RENOVATE_PR"
  echo "::notice::Skipping custom workflow to avoid conflicts"
  echo "skip=true" >> "$GITHUB_OUTPUT"
else
  echo "skip=false" >> "$GITHUB_OUTPUT"
fi
