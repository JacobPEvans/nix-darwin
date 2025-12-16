{
  # Nix-darwin flake configuration
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
      flake = false; # Not a flake, just fetch the repo
    };

    claude-cookbooks = {
      url = "github:anthropics/claude-cookbooks";
      flake = false; # Not a flake, just fetch the repo
    };

    # Official Anthropic plugin directory
    # Curated collection of internal and external plugins
    claude-plugins-official = {
      url = "github:anthropics/claude-plugins-official";
      flake = false; # Not a flake, just fetch the repo
    };

    # Anthropic public skills repository
    # Document generation, analysis, and other reusable skills
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false; # Not a flake, just fetch the repo
    };

    # Agent OS - spec-driven development system for AI coding agents
    # Provides standards, workflows, agents, and commands
    # https://buildermethods.com/agent-os
    # Forked to user's GitHub to mitigate upstream disappearing
    agent-os = {
      url = "github:JacobPEvans/agent-os";
      flake = false; # Not a flake, just fetch the repo
    };

    # AI Assistant Instructions - source of truth for AI agent configuration
    # Contains permissions, commands, and instruction files
    # Consumed by claude.nix to generate settings.json
    # Tracks main branch for cutting-edge updates (user's own repo)
    ai-assistant-instructions = {
      url = "github:JacobPEvans/ai-assistant-instructions";
      flake = false; # Not a flake, just fetch the repo
    };

    # Claude Code Statusline - modular multi-line terminal statusline
    # Provides git status, MCP monitoring, cost tracking, themes
    # https://github.com/rz1989s/claude-code-statusline
    claude-code-statusline = {
      url = "github:rz1989s/claude-code-statusline";
      flake = false; # Not a flake, just fetch the repo
    };

    # Superpowers - comprehensive software development workflow system
    # Provides brainstorming, planning, execution, testing, and review skills
    # https://github.com/obra/superpowers
    superpowers-marketplace = {
      url = "github:obra/superpowers-marketplace";
      flake = false; # Not a flake, just fetch the repo
    };

  };

  outputs =
    {
      nixpkgs,
      darwin,
      home-manager,
      mac-app-util,
      claude-code-plugins,
      claude-cookbooks,
      claude-plugins-official,
      anthropic-skills,
      agent-os,
      ai-assistant-instructions,
      claude-code-statusline,
      superpowers-marketplace,
      ...
    }:
    let
      userConfig = import ./lib/user-config.nix;
      hmDefaults = import ./lib/home-manager-defaults.nix;

      # Pure settings generator for CI (no derivations, cross-platform)
      # Reads permissions from flake inputs and generates settings attrset
      ciClaudeSettings = import ./lib/claude-settings.nix {
        homeDir = "/home/user"; # Placeholder - CI only validates schema structure
        schemaUrl = userConfig.ai.claudeSchemaUrl;
        permissions = {
          allow =
            (builtins.fromJSON (
              builtins.readFile "${ai-assistant-instructions}/.claude/permissions/allow.json"
            )).permissions;
          deny =
            (builtins.fromJSON (builtins.readFile "${ai-assistant-instructions}/.claude/permissions/deny.json"))
            .permissions;
          ask =
            (builtins.fromJSON (builtins.readFile "${ai-assistant-instructions}/.claude/permissions/ask.json"))
            .permissions;
        };
        plugins =
          (import ./modules/home-manager/ai-cli/claude-plugins.nix {
            inherit
              claude-code-plugins
              claude-cookbooks
              claude-plugins-official
              anthropic-skills
              ;
            inherit (nixpkgs) lib;
            config = { }; # Unused but required by signature
          }).pluginConfig;
      };

      # Pass external sources to home-manager modules
      extraSpecialArgs = {
        inherit
          claude-code-plugins
          claude-cookbooks
          claude-plugins-official
          anthropic-skills
          agent-os
          ai-assistant-instructions
          claude-code-statusline
          superpowers-marketplace
          ;
      };
      # Define configuration once, assign to multiple names
      darwinConfig = darwin.lib.darwinSystem {
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
              # Agent OS: Proper home-manager module for spec-driven AI development
              # Claude: Unified configuration for Claude Code ecosystem
              sharedModules = [
                mac-app-util.homeManagerModules.default
                ./modules/home-manager/ai-cli/agent-os
                ./modules/home-manager/ai-cli/claude
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
      # Pure Nix evaluation - no derivation building required, works cross-platform
      # Using 'lib' (standard flake output) to avoid 'unknown flake output' warning
      lib = {
        ci = {
          # Settings JSON generated from lib/claude-settings.nix (pure function)
          # Uses placeholder homeDir since CI only validates schema structure
          claudeSettingsJson = builtins.toJSON ciClaudeSettings;
          # Note: hmActivationPackage still requires Darwin (kept for macOS CI)
          hmActivationPackage =
            darwinConfig.config.home-manager.users.${userConfig.user.name}.home.activationPackage;
        };
      };

      # Formatter for `nix fmt` command (2025 best practice)
      # nixfmt-tree = treefmt pre-configured with nixfmt
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
            import ./lib/checks.nix {
              pkgs = nixpkgs.legacyPackages.${system};
              src = ./.;
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
