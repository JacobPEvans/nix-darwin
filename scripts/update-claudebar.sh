#!/usr/bin/env bash
# Update ClaudeBar package version and hash in overlays/macos-apps.nix
#
# Usage:
#   scripts/update-claudebar.sh           # Preview changes (dry run)
#   scripts/update-claudebar.sh --apply   # Apply changes to overlay

set -euo pipefail

APPLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=true; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

OVERLAY_FILE="$(dirname "$0")/../overlays/macos-apps.nix"

echo "Fetching latest ClaudeBar release from GitHub..."
LATEST_TAG=$(gh api repos/tddworks/ClaudeBar/releases/latest --jq '.tag_name')
VERSION="${LATEST_TAG#v}"
if [[ -z "${VERSION}" || ! "${VERSION}" =~ ^[0-9]+\.[0-9]+ ]]; then
  echo "Error: Failed to determine valid ClaudeBar version from tag '${LATEST_TAG}'" >&2
  exit 1
fi
echo "Latest version: $VERSION"

CURRENT_VERSION=$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$OVERLAY_FILE" | head -1)
if [ -z "$CURRENT_VERSION" ]; then
  echo "Error: Could not parse current version from $OVERLAY_FILE" >&2
  exit 1
fi
echo "Current version: $CURRENT_VERSION"

if [ "$VERSION" = "$CURRENT_VERSION" ]; then
  echo "Already at latest version $VERSION — no update needed."
  exit 0
fi

URL="https://github.com/tddworks/ClaudeBar/releases/download/v${VERSION}/ClaudeBar-${VERSION}.dmg"
echo "Computing hash for: $URL"
HASH=$(nix store prefetch-file --hash-type sha256 "$URL" 2>/dev/null \
  | grep -o 'sha256-[A-Za-z0-9+/=]*' \
  || nix-prefetch-url "$URL" 2>/dev/null | xargs -I{} nix hash convert --to sri --hash-algo sha256 {})
if [ -z "$HASH" ]; then
  echo "Error: Failed to compute hash for $URL" >&2
  exit 1
fi

echo ""
echo "Changes:"
echo "  version: $CURRENT_VERSION -> $VERSION"
echo "  hash:    $HASH"

if [ "$APPLY" = true ]; then
  # Portable in-place sed
  if sed --version 2>&1 | grep -q 'GNU sed'; then
    SED_I() { sed -i "$@"; }
  else
    SED_I() { sed -i '' "$@"; }
  fi

  # Escape dots in version string for use as a literal sed pattern
  CURRENT_VERSION_ESCAPED="${CURRENT_VERSION//./\\.}"
  SED_I "s/version = \"${CURRENT_VERSION_ESCAPED}\"/version = \"${VERSION}\"/" "$OVERLAY_FILE"
  SED_I "s|hash = \"sha256-[^\"]*\"|hash = \"${HASH}\"|" "$OVERLAY_FILE"
  echo "Applied changes to $OVERLAY_FILE"
else
  echo ""
  echo "Dry run. Pass --apply to update $OVERLAY_FILE"
fi
