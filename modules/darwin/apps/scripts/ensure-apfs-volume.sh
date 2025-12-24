#!/usr/bin/env bash
# ensure-apfs-volume.sh - Create APFS volume if it doesn't exist
#
# Minimal script - only handles diskutil operations that cannot be done in Nix.
# All configuration (paths, names) comes from arguments.
#
# Arguments:
#   $1 - Volume name
#   $2 - APFS container identifier (e.g., "disk3")
#
# Exit codes:
#   0 - Volume exists or was created
#   1 - Creation failed

set -euo pipefail

VOLUME_NAME="${1:?Volume name required}"
CONTAINER="${2:?APFS container required}"

# Validate volume name: allow only safe characters (letters, digits, dot, underscore, space, hyphen)
NAME_PATTERN="^[A-Za-z0-9._ -]+$"
if [[ ! "$VOLUME_NAME" =~ $NAME_PATTERN ]]; then
    echo "Error: Volume name contains invalid characters" >&2
    exit 1
fi

# Validate container: disk identifiers (disk3, disk3s1) or UUIDs
CONTAINER_PATTERN="^(disk[0-9]+([s][0-9]+)?|[A-Fa-f0-9-]{36})$"
if [[ ! "$CONTAINER" =~ $CONTAINER_PATTERN ]]; then
    echo "Error: Invalid container identifier" >&2
    exit 1
fi

MOUNT_POINT="/Volumes/${VOLUME_NAME}"

# Already mounted - done
if mount | grep -q " on ${MOUNT_POINT} "; then
    exit 0
fi

# Exists but not mounted - mount it
if diskutil info "${VOLUME_NAME}" &>/dev/null; then
    if ! diskutil mount "${VOLUME_NAME}"; then
        echo "Error: Failed to mount volume '${VOLUME_NAME}'" >&2
        exit 1
    fi
    exit 0
fi

# Create volume
if ! diskutil apfs addVolume "${CONTAINER}" APFS "${VOLUME_NAME}"; then
    echo "Error: Failed to create volume '${VOLUME_NAME}' on container '${CONTAINER}'" >&2
    exit 1
fi
exit 0
