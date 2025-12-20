#!/usr/bin/env bash
# Git merge driver for flake.lock
#
# Instead of 3-way merge, regenerate the lock file.
# Called by git with: %O (ancestor) %A (current) %B (other)
#
# Usage in .gitattributes:
#   flake.lock merge=flakelock
#
# Usage in git config:
#   [merge "flakelock"]
#     name = Regenerate flake.lock
#     driver = ~/.local/bin/git-merge-flakelock %O %A %B

set -euo pipefail

# Arguments from git
ANCESTOR="$1"  # %O - common ancestor
CURRENT="$2"   # %A - current version (ours) - we write result here
OTHER="$3"     # %B - other version (theirs)

# Regenerate flake.lock
# This updates flake.lock in the working directory
if nix flake lock 2>/dev/null; then
    # Copy regenerated lock to the merge result
    cp flake.lock "$CURRENT"
    exit 0
else
    # If regeneration fails, accept current version and let user handle it
    echo "Warning: flake.lock regeneration failed, keeping current version" >&2
    exit 0
fi
