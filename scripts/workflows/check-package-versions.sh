#!/usr/bin/env bash
# Package Version Monitoring Script
# Compares pinned package versions (from flake.lock) with latest on their branch
# Outputs markdown table for GitHub issue

set -uo pipefail

# Locate flake.lock relative to script (repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FLAKE_LOCK="$REPO_ROOT/flake.lock"

if [[ ! -f "$FLAKE_LOCK" ]]; then
  echo "ERROR: flake.lock not found at $FLAKE_LOCK" >&2
  exit 1
fi

# Check for required tools
if ! command -v jq &>/dev/null || ! command -v nix &>/dev/null; then
  echo "ERROR: jq and nix are required. Please run this script within a Nix environment (e.g., 'nix develop')." >&2
  exit 1
fi

# Package definitions: name:priority:channel
# Priority: Security (security-critical) | AI Tool (AI tooling) | GUI App (desktop apps)
# Channel: stable (nixpkgs-25.11-darwin) | unstable (nixpkgs-unstable)
PACKAGES=(
  "git:Security:stable"
  "gnupg:Security:stable"
  "gh:Security:stable"
  "nodejs:Security:stable"
  "codex:AI Tool:unstable"
  "github-mcp-server:AI Tool:unstable"
  "ollama:AI Tool:unstable"
  "terraform-mcp-server:AI Tool:unstable"
  "ghostty-bin:GUI App:unstable"
  "bitwarden-desktop:GUI App:stable"
  "chatgpt:GUI App:stable"
  "code-cursor:GUI App:stable"
  "postman:GUI App:stable"
  "rapidapi:GUI App:stable"
  "raycast:GUI App:stable"
  "swiftbar:GUI App:stable"
)

# Global counters for exit status
MAJOR_UPDATES=0
MINOR_UPDATES=0
CURRENT=0

# Pre-read locked revisions and branch refs from flake.lock (avoids repeated jq calls)
STABLE_REV=$(jq -r '.nodes["nixpkgs"].locked.rev // empty' "$FLAKE_LOCK")
UNSTABLE_REV=$(jq -r '.nodes["nixpkgs-unstable"].locked.rev // empty' "$FLAKE_LOCK")
STABLE_BRANCH=$(jq -r '.nodes["nixpkgs"].original.ref // empty' "$FLAKE_LOCK")
UNSTABLE_BRANCH=$(jq -r '.nodes["nixpkgs-unstable"].original.ref // empty' "$FLAKE_LOCK")

# Map channel to pre-cached rev/branch
get_locked_rev() {
  case "$1" in
    stable) echo "$STABLE_REV" ;;
    unstable) echo "$UNSTABLE_REV" ;;
    *) echo "" ;;
  esac
}

get_branch_ref() {
  case "$1" in
    stable) echo "$STABLE_BRANCH" ;;
    unstable) echo "$UNSTABLE_BRANCH" ;;
    *) echo "" ;;
  esac
}

# Get version from our pinned nixpkgs revision (what we actually have installed)
get_current_version() {
  local package=$1
  local rev
  rev=$(get_locked_rev "$2")

  if [[ -z "$rev" ]]; then
    echo "unknown"
    return
  fi

  nix eval "github:NixOS/nixpkgs/${rev}#${package}.version" --raw 2>/dev/null || echo "unknown"
}

# Get version from latest nixpkgs branch HEAD (what's available if we update)
get_latest_version() {
  local package=$1
  local branch
  branch=$(get_branch_ref "$2")

  if [[ -z "$branch" ]]; then
    echo "unknown"
    return
  fi

  nix eval "github:NixOS/nixpkgs/${branch}#${package}.version" --raw 2>/dev/null || echo "unknown"
}

# Function to compare versions and determine status
compare_versions() {
  local current=$1
  local latest=$2

  if [[ "$current" == "unknown" ]] || [[ "$latest" == "unknown" ]]; then
    echo "❓ Unknown"
    return 2
  fi

  if [[ "$current" == "$latest" ]]; then
    echo "✅ Current"
    return 0
  fi

  # Extract major.minor.patch
  local current_major current_minor
  current_major=$(echo "$current" | cut -d. -f1)
  current_minor=$(echo "$current" | cut -d. -f2)

  local latest_major latest_minor
  latest_major=$(echo "$latest" | cut -d. -f1)
  latest_minor=$(echo "$latest" | cut -d. -f2)

  # Compare major versions
  if [[ "$latest_major" -gt "$current_major" ]]; then
    echo "🔴 Major"
    return 3
  fi

  # Compare minor versions
  if [[ "$latest_major" -eq "$current_major" ]] && [[ "$latest_minor" -gt "$current_minor" ]]; then
    echo "⚠️ Minor"
    return 1
  fi

  # Patch update or same
  echo "⚠️ Patch"
  return 1
}

# Main execution
main() {
  echo "# Package Version Report - $(date -u +"%Y-%m-%d %H:%M UTC")"
  echo ""
  echo "| Package | Current | Latest | Status | Priority | Channel |"
  echo "|---------|---------|--------|--------|----------|---------|"

  for package_def in "${PACKAGES[@]}"; do
    IFS=':' read -r package priority channel <<< "$package_def"

    current_version=$(get_current_version "$package" "$channel")
    latest_version=$(get_latest_version "$package" "$channel")

    status=$(compare_versions "$current_version" "$latest_version")
    status_code=$?

    # Update counters based on return code
    case $status_code in
      0) ((CURRENT++)) ;;
      1) ((MINOR_UPDATES++)) ;;
      3) ((MAJOR_UPDATES++)) ;;
    esac

    echo "| $package | $current_version | $latest_version | $status | $priority | $channel |"
  done

  echo ""
  echo "## Legend"
  echo ""
  echo "- ✅ Current: Up to date"
  echo "- ⚠️ Minor/Patch: Minor or patch update available"
  echo "- 🔴 Major: Major version update available"
  echo "- ❓ Unknown: Unable to determine version"
  echo ""
  echo "---"
  echo ""
  echo "**Auto-updated**: This issue updates on Mon 7am, Thu 7pm, Sat 7am UTC  "
  echo "**Auto-closes**: When all packages show ✅ Current"
  echo ""
  echo "**Summary**: $CURRENT current, $MINOR_UPDATES minor/patch updates, $MAJOR_UPDATES major updates"

  # Exit codes:
  # 0 = all current
  # 1 = minor/patch updates available
  # 2 = major updates available
  if [[ $MAJOR_UPDATES -gt 0 ]]; then
    exit 2
  elif [[ $MINOR_UPDATES -gt 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

# Run main function
main
