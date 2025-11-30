# Development Environment Packages
#
# Base development packages shared across all dev profiles.
# This module collects packages from all subdirectories.
#
# Structure:
#   cloud/     - Cloud provider tools (AWS, etc.)
#   git/       - Git workflow tools (delta, gh, pre-commit)
#   linters/   - Code linting tools
#   node/      - Node.js runtime
#   security/  - Credential management tools
#   tools/     - Miscellaneous dev CLI tools
#   profiles/  - Profile-specific additions (work, personal)
#
# Usage:
#   Import this file and call with { inherit pkgs; } to get package list
#   Or import individual subdirectory files for specific categories

{ pkgs }:

let
  # Import all category packages
  awsPackages = import ./cloud/aws.nix { inherit pkgs; };
  gitTools = import ./git/tools.nix { inherit pkgs; };
  linters = import ./linters/common.nix { inherit pkgs; };
  nodePackages = import ./node/packages.nix { inherit pkgs; };
  securityTools = import ./security/bitwarden.nix { inherit pkgs; };
  cliTools = import ./tools/cli.nix { inherit pkgs; };
in
{
  # Base dev packages (all profiles get these)
  basePackages =
    awsPackages ++
    gitTools ++
    linters ++
    nodePackages ++
    securityTools ++
    cliTools;

  # Profile-specific packages
  workPackages = import ./profiles/work.nix { inherit pkgs; };
  personalPackages = import ./profiles/personal.nix { inherit pkgs; };

  # Convenience functions for shells
  allWorkPackages = pkgs:
    (import ./default.nix { inherit pkgs; }).basePackages ++
    (import ./profiles/work.nix { inherit pkgs; });

  allPersonalPackages = pkgs:
    (import ./default.nix { inherit pkgs; }).basePackages ++
    (import ./profiles/personal.nix { inherit pkgs; });
}
