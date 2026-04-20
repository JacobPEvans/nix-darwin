#!/usr/bin/env bash
# check-nixpkgs-channel.sh — Warn if nixpkgs flake.lock rev diverges from Hydra channel HEAD.
#
# Emits a GitHub Actions ::warning:: annotation when the locked nixpkgs rev is not the
# Hydra-evaluated channel rev. A mismatch means binary cache coverage may be sparse,
# causing slow builds (~130 GiB source builds instead of fast narinfo hits).
#
# Not a hard failure: the channel URL may lag briefly after a Hydra evaluation.
# The warning is sufficient signal for a PR author to decide whether to update first.

set -euo pipefail

CHANNEL_URL="https://channels.nixos.org/nixpkgs-25.11-darwin/git-revision"

channel_rev=$(curl -sfL "$CHANNEL_URL" || echo "")
flake_rev=$(jq -r '
  .nodes | to_entries[]
  | select(.value.original.ref? == "nixpkgs-25.11-darwin")
  | .value.locked.rev
' flake.lock | head -1)

if [ -z "$channel_rev" ]; then
  echo "Could not fetch channel rev from $CHANNEL_URL — skipping check"
  exit 0
fi

if [ -z "$flake_rev" ]; then
  echo "No nixpkgs-25.11-darwin input found in flake.lock — skipping check"
  exit 0
fi

if [ "$flake_rev" != "$channel_rev" ]; then
  echo "::warning::nixpkgs pinned to ${flake_rev:0:12} but channel is at ${channel_rev:0:12} — binary cache may be sparse; expect a slower build"
else
  echo "nixpkgs ${flake_rev:0:12} matches Hydra channel HEAD — binary cache coverage expected"
fi
