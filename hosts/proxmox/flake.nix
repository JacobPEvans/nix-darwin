{
  description = "Home-manager configuration for Proxmox Server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      userConfig = import ../../lib/user-config.nix;
    in {
      # Home-manager standalone configuration
      # Usage: home-manager switch --flake .#<username>
      # Where <username> is defined in lib/user-config.nix
      homeConfigurations.${userConfig.user.name} =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
        };
    };
}
