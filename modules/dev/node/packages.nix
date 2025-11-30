# Node.js Packages
#
# Node.js runtime with npm and npx.
# Uses stable nixpkgs versions (updates on nix flake update).

{ pkgs }:

with pkgs; [
  nodejs      # Node.js runtime (includes npm and npx)
]
