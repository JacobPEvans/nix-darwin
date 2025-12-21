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
#
# Configuration (injected via Nix substituteAll):
# - @keychainService@ : Keychain service name for BWS access token
# - @bwsSecretId@     : Bitwarden secret ID for Claude OAuth token

set -euo pipefail

# Get BWS access token from Keychain
BWS_TOKEN=$(security find-generic-password -s "@keychainService@" -w) || {
  echo "ERROR: Cannot retrieve BWS token from Keychain (service: @keychainService@)" >&2
  exit 1
}

# Check for required commands
if ! command -v bws &> /dev/null; then
  echo "ERROR: 'bws' command not found. Please ensure Bitwarden CLI is installed and in your PATH." >&2
  exit 1
fi
if ! command -v jq &> /dev/null; then
  echo "ERROR: 'jq' command not found. Please install 'jq' to parse JSON output." >&2
  exit 1
fi

# Validate BWS token format (must be non-empty and not contain obvious corruption markers)
if [[ -z "$BWS_TOKEN" || "$BWS_TOKEN" == "null" ]]; then
  echo "ERROR: BWS token is empty or null" >&2
  echo "Fix: Delete and re-add the token to Keychain:" >&2
  echo "  security delete-generic-password -s \"@keychainService@\"" >&2
  echo "  security add-generic-password -s \"@keychainService@\" -a \"\$USER\" -w \"NEW_TOKEN\"" >&2
  echo "Get a new token from: https://vault.bitwarden.com" >&2
  exit 1
fi

# Fetch OAuth token from BWS
export BWS_ACCESS_TOKEN="$BWS_TOKEN"

# Run bws and capture all output (stdout and stderr) - only call once for efficiency
BWS_OUTPUT=$(bws secret get "@bwsSecretId@" --output json 2>&1)
BWS_EXIT_CODE=$?

# If bws succeeded, try to parse the JSON
if [[ $BWS_EXIT_CODE -eq 0 ]]; then
  API_KEY=$(echo "$BWS_OUTPUT" | jq -r '.value' 2>/dev/null)
  JQ_EXIT_CODE=$?
  if [[ $JQ_EXIT_CODE -eq 0 && -n "$API_KEY" ]]; then
    echo "$API_KEY"
    exit 0
  fi
  # If we are here, jq failed or returned an empty key. Fall through to error handling.
fi

# Handle all errors here (bws failed or jq failed)
echo "ERROR: Cannot retrieve OAuth token from BWS (secret: @bwsSecretId@)" >&2

# Check for specific invalid token format error
if echo "$BWS_OUTPUT" | grep -q "not in a valid format"; then
  echo "" >&2
  echo "The BWS access token in your Keychain is invalid or corrupted." >&2
  echo "Fix: Replace the token with a new Machine Account token:" >&2
  echo "" >&2
  echo "  1. Delete the corrupted entry:" >&2
  echo "     security delete-generic-password -s \"@keychainService@\"" >&2
  echo "" >&2
  echo "  2. Get a new token from Bitwarden Secrets Manager:" >&2
  echo "     https://vault.bitwarden.com" >&2
  echo "" >&2
  echo "  3. Add to keychain:" >&2
  echo "     security add-generic-password -s \"@keychainService@\" -a \"\$USER\" -w \"NEW_TOKEN\"" >&2
  echo "" >&2
  echo "  4. Verify:" >&2
  echo "     export BWS_ACCESS_TOKEN=\$(security find-generic-password -s \"@keychainService@\" -w)" >&2
  echo "     bws secret list" >&2
else
  echo "BWS error: $BWS_OUTPUT" >&2
fi
exit 1
