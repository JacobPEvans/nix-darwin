# Common Packages
#
# Universal packages shared across ALL systems (macOS, Linux, etc.)
# These are truly cross-platform essentials.
#
# Usage:
#   - Darwin: imported in darwin/common.nix
#   - Linux:  imported in linux/common.nix
#
# NOTE: This file returns a function that takes pkgs and returns a list.
# Currently empty - packages have been moved to more specific locations:
#   - Development tools → modules/dev/
#   - macOS packages → modules/darwin/packages/
#   - Linux packages → modules/linux/packages/ (future)

{ pkgs }:

with pkgs; [
  # Add truly universal packages here (ones needed on EVERY system)
  # Example: curl, wget, etc.
]
