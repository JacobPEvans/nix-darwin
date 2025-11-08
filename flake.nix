# Based on https://github.com/MatthiasBenaets/nix-config/blob/master/flake.nix
#
#  flake.nix *
#   ├─ ./hosts
#   │   └─ default.nix
#   ├─ ./darwin
#   │   └─ default.nix
#   └─ ./nix
#       └─ default.nix
#

{

  description = "Jacob's nix-darwin system configuration";

  inputs = {
    # Package sets
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";

    # Environment/system management
    darwin = {
        url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
        inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
        url = "github:nix-community/home-manager/release-25.05";
        inputs.nixpkgs.follows = "nixpkgs";
    }

    # Other sources
    comma = {
        url = github:Shopify/comma;
        flake = false;
    };

    # Neovim
    nixvim = {
        url = "github:nix-community/nixvim";
        inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim
    nixvim-stable = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    
    # Mac-specific
    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, darwin, home-manager, comma, nixvim, nixvim-stable, mac-app-util, ... }:
  
    let
      # Flake Variables
      vars = {
        version = "25.05";
        user = "jevans";
        location = "$HOME/.setup";
        editor = "vim";
      };
    in
    {
      nixosConfigurations = (
        import ./hosts {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs nixpkgs-stable home-manager comma nixvim mac-app-util vars; # Inherit inputs
        }
      );

      darwinConfigurations = (
        import ./darwin {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs nixpkgs-stable darwin home-manager comma nixvim mac-app-util vars;
        }
      );

      homeConfigurations = (
        import ./nix {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs nixpkgs-stable home-manager comma vars;
        }
      );
    };
}
