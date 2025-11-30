# Darwin Packages Index
#
# Combines all package categories for macOS systems.
# Import this file to get all darwin-specific packages.

{ pkgs, ... }:

let
  gitPackages = import ./git.nix { inherit pkgs; };
  corePackages = import ./core.nix { inherit pkgs; };
  cliPackages = import ./cli.nix { inherit pkgs; };
  productivityPackages = import ./productivity.nix { inherit pkgs; };
in
{
  imports = [
    ./homebrew.nix
  ];

  environment.systemPackages =
    gitPackages ++
    corePackages ++
    cliPackages ++
    productivityPackages;
}
