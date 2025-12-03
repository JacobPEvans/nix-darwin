{
  description = "nix-darwin configuration for M4 Max MacBook Pro";

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

    # mac-app-util: Create stable app trampolines to preserve macOS permissions
    # Without this, TCC permissions (camera, microphone, screen recording) are
    # revoked on every rebuild because Nix store paths change.
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
      # WORKAROUND: gitlab.common-lisp.net has Anubis anti-bot protection
      # blocking automated fetches. Use fork with GitHub mirror URLs.
      # See: https://github.com/hraban/mac-app-util/issues/39
      inputs.cl-nix-lite.url = "github:r4v3n6101/cl-nix-lite/url-fix";
    };

    # Official Anthropic repositories for Claude Code plugins/commands
    # These provide slash commands, agents, and skills for Claude Code
    claude-code-plugins = {
      url = "github:anthropics/claude-code";
      flake = false;  # Not a flake, just fetch the repo
    };

    claude-cookbooks = {
      url = "github:anthropics/claude-cookbooks";
      flake = false;  # Not a flake, just fetch the repo
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, mac-app-util, claude-code-plugins, claude-cookbooks, ... }:
    let
      userConfig = import ./lib/user-config.nix;
      hmDefaults = import ./lib/home-manager-defaults.nix;

      # Pass external sources to home-manager modules
      extraSpecialArgs = {
        inherit claude-code-plugins claude-cookbooks;
      };
    in
    {
      darwinConfigurations.default = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/macbook-m4/default.nix

          # mac-app-util: Creates stable trampolines for GUI apps
          # Preserves TCC permissions (camera, mic, screen) across rebuilds
          mac-app-util.darwinModules.default

          home-manager.darwinModules.home-manager
          {
            home-manager = hmDefaults // {
              inherit extraSpecialArgs;
              users.${userConfig.user.name} = import ./hosts/macbook-m4/home.nix;

              # mac-app-util: Also needed for home.packages if any GUI apps there
              sharedModules = [
                mac-app-util.homeManagerModules.default
              ];
            };
          }
        ];
      };
    };
}
