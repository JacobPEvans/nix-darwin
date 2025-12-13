#!/usr/bin/env zsh
# Retrieves Claude OAuth token from Bitwarden Secrets Manager
# BWS access token is stored in macOS Keychain for security
#
# Security architecture:
# 1. BWS access token stored in macOS login Keychain (encrypted at rest)
# 2. Claude OAuth token stored in BWS (cloud secrets with audit trail)
# 3. Token never written to disk - fetched at runtime
#
# Used by Claude Code's apiKeyHelper mechanism for headless authentication
# (cron jobs, CI/CD pipelines, etc.)

set -euo pipefail

# Get BWS access token from Keychain
BWS_TOKEN=$(security find-generic-password -s "bws-claude-automation" -w 2>/dev/null) || {
  echo "ERROR: Cannot retrieve BWS token from Keychain" >&2
  exit 1
}

# Fetch OAuth token from BWS
export BWS_ACCESS_TOKEN="$BWS_TOKEN"
bws secret get "55ebeb62-1327-4967-8f08-b3a5015f5b7b" --output json 2>/dev/null | jq -r '.value' || {
  echo "ERROR: Cannot retrieve OAuth token from BWS" >&2
  exit 1
}
