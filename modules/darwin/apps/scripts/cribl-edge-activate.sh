#!/usr/bin/env bash
# cribl-edge-activate.sh - Install Cribl Edge via the Cribl Cloud install script
#
# Uses the official Cribl install-edge.sh endpoint which handles:
# - Binary download and installation via .pkg
# - Fleet enrollment (writes instance.yml)
# - Version management
#
# Arguments:
#   $1 - Cloud host (e.g., "main-orgid.cribl.cloud")
#   $2 - Fleet group name (e.g., "default_fleet")
#   $3 - Auth token
#   $4 - Version string (e.g., "4.17.0-7e952fa7")
#   $5 - Install path (e.g., "/opt/cribl")
#   $6 - Service user (e.g., "root")
#   $7 - Service group (e.g., "wheel")
#
# Exit codes:
#   0 - Installation successful
#   1 - Installation failed

CLOUD_HOST="$1"
FLEET_GROUP="$2"
TOKEN="$3"
VERSION="$4"
INSTALL_PATH="$5"
SERVICE_USER="$6"
SERVICE_GROUP="$7"

TS="$(date '+%Y-%m-%d %H:%M:%S')"

# Stop Nix-managed service before install
/bin/launchctl bootout system/com.nix-darwin.cribl-edge 2>/dev/null || true

# Use Cribl Cloud's official install script.
# URL is passed via curl --config stdin (not a command-line arg) to keep the
# enrollment token out of process listings.
# Script is downloaded to a temp file first so we can do a basic sanity check
# before executing. Cribl's install script is dynamically generated per request
# (embeds enrollment params), so no pre-computed hash is available.
echo "${TS} [INFO] Installing Cribl Edge ${VERSION}..."
_tmpscript=$(mktemp /tmp/cribl-install-XXXXXX.sh)
trap 'rm -f "$_tmpscript"' EXIT
curl --config - --output "$_tmpscript" << CURL_EOF
url = "https://${CLOUD_HOST}/init/install-edge.sh?group=${FLEET_GROUP}&token=${TOKEN}&user=${SERVICE_USER}&user_group=${SERVICE_GROUP}&version=${VERSION}"
fail
silent
show-error
location
CURL_EOF
# Basic sanity: non-empty file with a shell shebang
if [ ! -s "$_tmpscript" ] || ! head -1 "$_tmpscript" | grep -q '^#!'; then
  echo "${TS} [ERROR] Downloaded Cribl install script looks invalid" >&2
  exit 1
fi
bash "$_tmpscript"

# Installer drops its own plist — tear it down, Nix manages the service
/bin/launchctl bootout system/io.cribl 2>/dev/null || true
rm -f /Library/LaunchDaemons/io.cribl.plist
echo "${TS} [INFO] Cribl Edge ${VERSION} installed"

# Fix ownership
/usr/sbin/chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "${INSTALL_PATH}"

# Remove cribl user/group if present (created by pkg, not needed when running as root)
if /usr/bin/dscl . -read /Users/cribl >/dev/null 2>&1; then
  /usr/bin/dscl . -delete /Users/cribl 2>/dev/null || true
  echo "${TS} [INFO] Removed cribl user (service runs as root)"
fi
if /usr/bin/dscl . -read /Groups/cribl >/dev/null 2>&1; then
  /usr/bin/dscl . -delete /Groups/cribl 2>/dev/null || true
  echo "${TS} [INFO] Removed cribl group"
fi

# Clean up stale cribl ACLs from previous user-based install (idempotent)
ACL="cribl allow read,readattr,readextattr,readsecurity,list,search"
for p in /var/log /var/log/asl /var/log/DiagnosticMessages /var/audit /Library/Logs /Library/Logs/DiagnosticReports; do
  [ -e "$p" ] && /bin/chmod -a "$ACL" "$p" 2>/dev/null || true
done

# Re-bootstrap plist (bootout above removed it from bootstrap context)
# and start the Nix-managed service
/bin/launchctl bootstrap system /Library/LaunchDaemons/com.nix-darwin.cribl-edge.plist 2>/dev/null || true
/bin/launchctl kickstart system/com.nix-darwin.cribl-edge 2>/dev/null || true
echo "${TS} [INFO] Cribl Edge service started"
