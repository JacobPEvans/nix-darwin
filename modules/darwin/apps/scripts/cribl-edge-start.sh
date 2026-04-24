#!/usr/bin/env bash
# Cribl Edge startup script.
#
# Arguments (set by the Nix wrapper in cribl-edge.nix):
#   $1 = path to sops-rendered KEY=value secrets file (root-only 0400)
#   $2 = CRIBL_VOLUME_DIR (mutable state / data dir)
#   $3 = CRIBL_HOME (read-only path into the Nix store package)
#   $4 = Cribl fleet group name
#
# Responsibilities:
#   1. Safely load CRIBL_ORG_ID / CRIBL_WORKSPACE_ID / CRIBL_TOKEN from the
#      secrets file without shell eval (no `source` of arbitrary content).
#   2. Ensure the data + log directories exist.
#   3. On first start, enroll as a managed edge node with Cribl Cloud and
#      drop an .enrolled marker so subsequent starts are a no-op. Enrollment
#      failures are fatal — launchd will retry via ThrottleInterval.
#   4. exec `cribl server`.

set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }

SECRETS_FILE="${1:?secrets file path required}"
CRIBL_VOLUME_DIR="${2:?volume dir required}"
CRIBL_HOME="${3:?cribl home required}"
CRIBL_GROUP="${4:?cribl fleet group required}"

export CRIBL_VOLUME_DIR CRIBL_HOME

if [ ! -r "$SECRETS_FILE" ]; then
  echo "$(ts) [ERROR] Cribl secrets file not readable: $SECRETS_FILE" >&2
  exit 1
fi

# Parse KEY=value without eval. Only whitelisted keys are honored; every other
# line is silently ignored so a malformed or tampered file cannot inject shell.
CRIBL_ORG_ID=""
CRIBL_WORKSPACE_ID=""
CRIBL_TOKEN=""
while IFS='=' read -r _key _value || [ -n "$_key" ]; do
  case "$_key" in
    ""|\#*) continue ;;
    CRIBL_ORG_ID)       CRIBL_ORG_ID="$_value" ;;
    CRIBL_WORKSPACE_ID) CRIBL_WORKSPACE_ID="$_value" ;;
    CRIBL_TOKEN)        CRIBL_TOKEN="$_value" ;;
  esac
done < "$SECRETS_FILE"
export CRIBL_ORG_ID CRIBL_WORKSPACE_ID CRIBL_TOKEN

mkdir -p "$CRIBL_VOLUME_DIR" "$CRIBL_VOLUME_DIR/logs"

# Enroll once per data volume. The .enrolled marker guards idempotency so that
# a hard failure of mode-managed-edge (missing/revoked token, network outage)
# surfaces via launchd rather than being silently swallowed.
if [ ! -f "$CRIBL_VOLUME_DIR/.enrolled" ] \
   && [ ! -f "$CRIBL_VOLUME_DIR/local/_system/instance.yml" ] \
   && [ ! -f "$CRIBL_VOLUME_DIR/local/edge/instance.yml" ]; then
  echo "$(ts) [INFO] Enrolling Cribl Edge to cloud..."
  if [ -z "${CRIBL_WORKSPACE_ID:-}" ] || [ -z "${CRIBL_ORG_ID:-}" ] || [ -z "${CRIBL_TOKEN:-}" ]; then
    echo "$(ts) [ERROR] Missing required Cribl secrets for enrollment." >&2
    exit 1
  fi

  "$CRIBL_HOME/bin/cribl" mode-managed-edge \
    -H "${CRIBL_WORKSPACE_ID}-${CRIBL_ORG_ID}.cribl.cloud" \
    -p 443 \
    -u "$CRIBL_TOKEN" \
    -g "$CRIBL_GROUP" \
    -S true

  : > "$CRIBL_VOLUME_DIR/.enrolled"
  echo "$(ts) [INFO] Cribl Edge enrolled."
fi

exec "$CRIBL_HOME/bin/cribl" server
