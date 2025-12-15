# NixOS version tracking
# Used by GitHub Actions to check for new stable releases
#
# stableVersion: Latest stable NixOS release branch
# Format: "YY.MM" (e.g., "25.11" for November 2025 release)
#
# Note: This repo uses nixpkgs-unstable in flake.nix for cutting-edge packages.
# This field tracks the latest stable release for informational purposes only.
# See .github/workflows/nixos-release-check.yml for automated update notifications.
{
  stableVersion = "25.11";
}
