# Git Development Tools
#
# Enhanced git tooling for development workflows.
# These complement the base git package in darwin/packages/git.nix

{ pkgs }:

with pkgs; [
  delta       # Better git diff viewer with syntax highlighting
  gh          # GitHub CLI for PR/issue management
  pre-commit  # Framework for managing git pre-commit hooks
]
