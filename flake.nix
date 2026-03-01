{
  # Nix-darwin flake configuration
  description = "nix-darwin configuration for M4 Max MacBook Pro";

  inputs = {
    # Using stable nixpkgs-25.11 for reliability
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

    # Using unstable nixpkgs for fast-moving packages (select GUI apps and AI CLI tools)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Consolidated systems input for darwin-only configuration
    # All transitive dependencies should follow this to avoid duplicate systems entries
    systems.url = "github:nix-systems/default-darwin";

    # Using stable nix-darwin-25.11 to match nixpkgs
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Using stable home-manager release-25.11 to match nixpkgs
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # mac-app-util: Create app trampolines for /Applications/Nix Apps/ (system-level)
    # Used ONLY at darwin level for environment.systemPackages apps.
    # Home-manager apps use copyApps instead (see hosts/macbook-m4/home.nix).
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      # Consolidate all input overrides in a single attrset
      # - nixpkgs: use our root nixpkgs
      # - systems: use our consolidated darwin-only systems
      # - treefmt-nix: transitive dependency, prevent duplicate nixpkgs in flake.lock
      # - cl-nix-lite: WORKAROUND for gitlab.common-lisp.net Anubis anti-bot protection
      #   See: https://github.com/hraban/mac-app-util/issues/39
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
        treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
        cl-nix-lite.url = "github:r4v3n6101/cl-nix-lite/url-fix";
      };
    };

    # AI CLI ecosystem (Claude, Gemini, Copilot, MCP, marketplace)
    # Self-contained: injects its own flake inputs via _module.args
    nix-ai = {
      url = "github:JacobPEvans/nix-ai";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Cross-platform home-manager modules (git, zsh, vscode, monitoring, shells)
    nix-home = {
      url = "github:JacobPEvans/nix-home";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      darwin,
      home-manager,
      mac-app-util,
      nix-ai,
      nix-home,
      ...
    }:
    let
      userConfig = import ./lib/user-config.nix;
      hmDefaults = import ./lib/home-manager-defaults.nix;

      # Import nixpkgs-unstable for fast-moving packages (select GUI apps and AI CLI tools)
      unstablePkgs = import nixpkgs-unstable {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };

      # Pass external sources to home-manager modules
      # nix-ai modules get their inputs via _module.args (self-contained)
      # nix-home modules accept userConfig with sensible defaults
      extraSpecialArgs = {
        inherit unstablePkgs userConfig;
      };

      # Define configuration once, assign to multiple names
      darwinConfig = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit unstablePkgs; };
        modules = [
          ./hosts/macbook-m4/default.nix

          # mac-app-util: Creates trampolines for system-level apps (/Applications/Nix Apps/)
          mac-app-util.darwinModules.default

          home-manager.darwinModules.home-manager
          {
            home-manager = hmDefaults // {
              inherit extraSpecialArgs;
              users.${userConfig.user.name} = import ./hosts/macbook-m4/home.nix;

              # Shared modules from external flakes:
              # - nix-ai: Claude, Gemini, Copilot, MCP servers, marketplace plugins
              # - nix-home: git, zsh, vscode, direnv, monitoring, tmux, common packages
              #
              # NOTE: mac-app-util home-manager module REMOVED - using copyApps instead.
              # copyApps copies apps to ~/Applications/Home Manager Apps/ with stable paths,
              # making mac-app-util trampolines redundant for TCC permission persistence.
              # The darwin-level mac-app-util module is still used for /Applications/Nix Apps/.
              sharedModules = [
                nix-ai.homeManagerModules.default
                nix-home.homeManagerModules.default
              ];
            };
          }
        ];
      };
    in
    {
      # Both names point to same config:
      # - "default" for explicit #default usage
      # - hostname for auto-detection when # is omitted
      darwinConfigurations = {
        default = darwinConfig;
        ${userConfig.host.name} = darwinConfig;
      };

      # CI-friendly outputs for GitHub Actions validation
      # Claude settings JSON now computed by nix-ai (self-contained)
      # hmActivationPackage still requires Darwin (kept for macOS CI)
      lib = {
        ci = {
          inherit (nix-ai.lib.ci) claudeSettingsJson;
          hmActivationPackage =
            darwinConfig.config.home-manager.users.${userConfig.user.name}.home.activationPackage;
        };
      };

      # Formatter for `nix fmt` command
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;

      # Quality checks for `nix flake check` (DRY principle)
      # Single source of truth for pre-commit hooks and GitHub Actions
      # Definitions in lib/checks.nix for better modularity
      # Cross-platform: works on all systems
      checks =
        nixpkgs.lib.genAttrs
          [
            "aarch64-darwin"
            "x86_64-darwin"
            "x86_64-linux"
            "aarch64-linux"
          ]
          (
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            import ./lib/checks.nix {
              inherit pkgs;
              src = ./.;
              darwinConfigurations = if system == "aarch64-darwin" then { default = darwinConfig; } else { };
            }
          );

      # Development shell for CI and local nix tooling
      devShells.aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShell {
        packages = with nixpkgs.legacyPackages.aarch64-darwin; [
          nixfmt-rfc-style
          statix
          deadnix
          treefmt
        ];
      };
    };
}
