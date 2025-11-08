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
      pkgs = import inputs.nixpkgs { system = "${vars.system_arch}"; };
      pypi = with pkgs; (ps: with ps; [
        pip
      ]);
    in
    {
      # default host
      devShells.${vars.system_arch}.default = inputs.nixpkgs.legacyPackages.${vars.system_arch}.mkShell {
        buildInputs = [ (pkgs.python310.withPackages pypi) ];
      };
      # py311 host
      devShells.${vars.system_arch}.py311 = inputs.nixpkgs.legacyPackages.${vars.system_arch}.mkShell {
        buildInputs = [ (pkgs.python311.withPackages pypi) ];
      };
    };
}
