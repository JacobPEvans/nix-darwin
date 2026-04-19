#!/usr/bin/env bash
# cribl-edge-deploy-pack.sh - Deploy a Cribl Edge pack idempotently
#
# Copies a pack from the Nix store to the Cribl Edge packs directory,
# registers it in package.json if missing, and reports deployment status.
#
# Arguments:
#   $1 - Pack name (simple basename, no slashes — validated)
#   $2 - Pack source path (Nix store derivation)
#   $3 - Cribl install path (e.g., "/opt/cribl")
#   $4 - Service user
#   $5 - Service group
#
# Output (stdout): "unchanged" | "deployed" | "registered" | "deployed and registered"
# Exit codes:
#   0 - Success
#   1 - Invalid pack name

PACK_NAME="$1"
PACK_SRC="$2"
CRIBL_PATH="$3"
SERVICE_USER="$4"
SERVICE_GROUP="$5"
STATUS="unchanged"

# Validate pack name (activation runs as root — prevent directory traversal)
case "$PACK_NAME" in
  ""|*/*|*..*)
    echo "Invalid pack name '$PACK_NAME': must be a simple basename" >&2
    exit 1
    ;;
esac

TARGET="$CRIBL_PATH/default/$PACK_NAME"
MARKER="$TARGET/.nix-store-path"

# Deploy if store path changed (stage to tmp dir, then atomic mv)
if [ ! -f "$MARKER" ] || [ "$(cat "$MARKER" 2>/dev/null)" != "$PACK_SRC" ]; then
  STAGING="${TARGET}.tmp.$$"
  rm -rf "$STAGING" "$TARGET"
  cp -R "$PACK_SRC" "$STAGING"
  /usr/sbin/chown -R "$SERVICE_USER:$SERVICE_GROUP" "$STAGING"
  mv "$STAGING" "$TARGET"
  echo "$PACK_SRC" > "$MARKER"
  STATUS="deployed"
fi

# Register in package.json if missing (uses jq --arg to keep $CRIBL_HOME literal)
if [ -f "$CRIBL_PATH/package.json" ] && \
   ! jq -e --arg n "$PACK_NAME" '.dependencies[$n]' "$CRIBL_PATH/package.json" >/dev/null 2>&1; then
  jq --arg n "$PACK_NAME" --arg v "file:\$CRIBL_HOME/default/$PACK_NAME" \
    '.dependencies |= ((if type == "object" then . else {} end) + {($n): $v})' \
    "$CRIBL_PATH/package.json" > "$CRIBL_PATH/package.json.tmp"
  mv "$CRIBL_PATH/package.json.tmp" "$CRIBL_PATH/package.json"
  /usr/sbin/chown "$SERVICE_USER:$SERVICE_GROUP" "$CRIBL_PATH/package.json"
  if [ "$STATUS" = "unchanged" ]; then
    STATUS="registered"
  else
    STATUS="$STATUS and registered"
  fi
fi

echo "$STATUS"
