#!/usr/bin/env bash
# Cribl Edge activation helper.
#
# Ensures the mutable data + log directories exist and are owned by the
# service account before launchd starts the daemon. Runs on every
# darwin-rebuild activation so non-root serviceUser configurations work
# regardless of whether packs are declared.
#
# Arguments (bound by the Nix caller in cribl-edge.nix):
#   $1 = dataDir (e.g. /opt/cribl-data)
#   $2 = serviceUser:serviceGroup chown target (e.g. root:wheel)

set -euo pipefail

DATA_DIR="${1:?dataDir required}"
OWNER="${2:?owner:group required}"

mkdir -p "$DATA_DIR" "$DATA_DIR/logs"
/usr/sbin/chown -R "$OWNER" "$DATA_DIR"
