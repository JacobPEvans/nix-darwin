# Common Packages
#
# Universal packages that should be installed on ALL systems (macOS, Linux, etc.)
# These are system-level tools, not user-specific.
#
# Usage:
#   - Darwin: imported in darwin/common.nix → environment.systemPackages
#   - Linux:  imported in linux/common.nix → home.packages (home-manager standalone)
#
# NOTE: This file returns a function that takes pkgs and returns a list of packages.

{ pkgs }:

with pkgs; [
  # ==========================================================================
  # Git & Pre-commit Hooks
  # ==========================================================================
  # Framework for managing git pre-commit hooks - essential for code quality
  pre-commit

  # ==========================================================================
  # Universal Linters
  # ==========================================================================
  # These are the most common linters used across projects. They support
  # pre-commit hooks and should be available on any development machine.

  # Shell
  shellcheck                      # Shell script static analysis (POSIX, bash)
  shfmt                           # Shell script formatter

  # Documentation
  markdownlint-cli2               # Markdown linter (README, docs exist everywhere)

  # CI/CD
  actionlint                      # GitHub Actions workflow linter

  # Nix
  nixfmt-classic                  # Nix code formatter (this repo uses Nix)
]
