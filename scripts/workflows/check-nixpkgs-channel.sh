#!/usr/bin/env bash
# check-nixpkgs-channel.sh — Warn if nixpkgs flake.lock rev diverges from Hydra channel Head.
#
# Emits a GitHub Actions ::warning:: annotation when the locked nixpkgs rev is not the
# Hydra-evaluated channel rev. A mismatch means binary cache coverage may be sparse,
# causing slow builds (~130 GiB source builds instead of fast narinfo hits).
#
# Not a hard failure: the channel URL may lag briefly after a Hydra evaluation.
# The warning is sufficient signal for a PR author to decide whether to update first.

set -euo pipefail

CHANNEL_NAME=$(jq -r '.nodes | to_entries[] | select(.value.original.ref? | test("^nixpkgs-")) | .value.original.ref' flake.lock | head -1)
if [ -z "$CHANNEL_NAME" ]; then
  echo "No nixpkgs channel input found in flake.lock — skipping check"
  exit 0
fi

CHANNEL_URL="https://channels.nixos.org/$CHANNEL_NAME/git-revision"

channel_rev=$(curl --connect-timeout 5 --max-time 15 -sfL "$CHANNEL_URL" || echo "")
flake_rev=$(jq -r --arg ref "$CHANNEL_NAME" '
  .nodes | to_entries[]
  | select(.value.original.ref? == $ref)
  | .value.locked.rev
' flake.lock | head -1)

if [ -z "$channel_rev" ]; then
  echo "Could not fetch channel rev from $CHANNEL_URL — skipping check"
  exit 0
fi

if [ -z "$flake_rev" ]; then
  echo "No $CHANNEL_NAME input found in flake.lock — skipping check"
  exit 0
fi

if [ "$flake_rev" != "$channel_rev" ]; then
  echo "::warning::nixpkgs pinned to ${flake_rev:0:12} but channel is at ${channel_rev:0:12} — binary cache may be sparse; expect a slower build"
else
  echo "nixpkgs ${flake_rev:0:12} matches Hydra channel HEAD — binary cache coverage expected"
fi
