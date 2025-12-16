#!/usr/bin/env bash
# Package Version Monitoring Script
# Compares current package versions with latest available in nixpkgs
# Outputs markdown table for GitHub issue

set -uo pipefail

# Package definitions: name, priority
# Priority: Security (security-critical) | AI Tool (AI tooling)
PACKAGES=(
  "git:Security"
  "gnupg:Security"
  "gh:Security"
  "nodejs:Security"
  "claude-code:AI Tool"
  "claude-monitor:AI Tool"
  "gemini-cli:AI Tool"
  "ollama:AI Tool"
)

# Global counters for exit status
MAJOR_UPDATES=0
MINOR_UPDATES=0
CURRENT=0

# Function to extract version from nix package
# Returns version string via stdout, or "unknown" if unable to determine
get_current_version() {
  local package=$1

  # Try to get version from nix eval
  if nix eval "nixpkgs#${package}.version" --raw 2>/dev/null; then
    return
  fi

  # Fallback: try to find installed version
  if command -v "$package" &>/dev/null; then
    case "$package" in
      git) git --version | awk '{print $3}' ;;
      gnupg) gpg --version | head -n1 | awk '{print $3}' ;;
      gh) gh --version | head -n1 | awk '{print $3}' ;;
      nodejs) node --version | sed 's/v//' ;;
      *) echo "unknown" ;;
    esac
    return
  fi

  echo "unknown"
}

# Function to get latest version from nixpkgs
get_latest_version() {
  local package=$1

  # Query nixpkgs for latest version using nix eval (much faster than nix search)
  nix eval "nixpkgs#${package}.version" --raw 2>/dev/null || echo "unknown"
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
  echo "| Package | Current | Latest | Status | Priority |"
  echo "|---------|---------|--------|--------|----------|"

  for package_def in "${PACKAGES[@]}"; do
    IFS=':' read -r package priority <<< "$package_def"

    current_version=$(get_current_version "$package")
    latest_version=$(get_latest_version "$package")
    status=$(compare_versions "$current_version" "$latest_version")
    status_code=$?

    # Update counters based on return code
    case $status_code in
      0) ((CURRENT++)) ;;
      1) ((MINOR_UPDATES++)) ;;
      3) ((MAJOR_UPDATES++)) ;;
    esac

    echo "| $package | $current_version | $latest_version | $status | $priority |"
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
