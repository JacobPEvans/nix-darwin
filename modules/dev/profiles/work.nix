# Work Development Profile
#
# Additional packages and configuration for work projects.
# Inherits all base dev packages plus work-specific tools.
#
# Usage: Used by dev-work shell in flake.nix

{ pkgs }:

with pkgs; [
  # Add work-specific packages here
  # Examples:
  # terraform       # Infrastructure as code
  # kubectl         # Kubernetes CLI
  # postgresql      # PostgreSQL client
]
