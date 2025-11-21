{
  description = "Minimal nix-darwin configuration for M4 Max MacBook Pro";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }: {
    darwinConfigurations.default = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./darwin/configuration.nix
        home-manager.darwinModules.home-manager
        {
          # Allow unfree packages (for proprietary software)
          nixpkgs.config.allowUnfree = true;

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.jevans = import ./home/home.nix;
        }
      ];
    };
  };
}
