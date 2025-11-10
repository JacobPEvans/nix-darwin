#
#  Example of a python development shell flake that allows for multiple versions and hosts
#  Can be run with "$ nix develop" or "$ nix develop </path/to/flake.nix>#<host>"
#

{
  description = "A python development environment";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixpkgs-unstable"; };
  };

  outputs = inputs:
    let
      pkgs = import inputs.nixpkgs { system = "aarch64-darwin"; };
      pypi = with pkgs; (ps: with ps; [
        pip
      ]);
    in
    {
      # default host
      devShells.aarch64-darwin.py312 = inputs.nixpkgs.legacyPackages.aarch64-darwin.mkShell {
        buildInputs = [ (pkgs.python312.withPackages pypi) ];
      };
      # py313 host
      devShells.aarch64-darwin.py313 = inputs.nixpkgs.legacyPackages.aarch64-darwin.mkShell {
        buildInputs = [ (pkgs.python313.withPackages pypi) ];
      };
    };
}