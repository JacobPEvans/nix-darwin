{
  # Nix-darwin flake configuration
  description = "nix-darwin configuration for M4 Max MacBook Pro";

  inputs = {
    # Using stable nixpkgs-25.11 for reliability
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

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

    # Official Anthropic repositories for Claude Code plugins/commands
    # These provide slash commands, agents, and skills for Claude Code
    # Pinned to specific release tag for stability (uses semantic versioning)
    claude-code-plugins = {
      url = "github:anthropics/claude-code/v2.1.12";
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
    agent-os = {
      url = "github:buildermethods/agent-os";
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

    # Superpowers - comprehensive software development workflow system
    # Provides brainstorming, planning, execution, testing, and review skills
    # https://github.com/obra/superpowers
    superpowers-marketplace = {
      url = "github:obra/superpowers-marketplace";
      flake = false; # Not a flake, just fetch the repo
    };

    # User's personal Claude Code plugins
    # Contains: git-rebase-workflow, webfetch-guard, markdown-validator, token-validator, issue-limiter
    # https://github.com/JacobPEvans/claude-code-plugins
    jacobpevans-cc-plugins = {
      url = "github:JacobPEvans/claude-code-plugins";
      flake = false; # Not a flake, just fetch the repo
    };

    # Claude Code Workflows - Backend, testing, code quality
    claude-code-workflows = {
      url = "github:wshobson/agents";
      flake = false;
    };

    # Claude Skills Marketplace - 174 production-ready skills
    claude-skills = {
      url = "github:secondsky/claude-skills";
      flake = false;
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
      superpowers-marketplace,
      jacobpevans-cc-plugins,
      claude-code-workflows,
      claude-skills,
      ...
    }:
    let
      userConfig = import ./lib/user-config.nix;
      hmDefaults = import ./lib/home-manager-defaults.nix;

      # Pure settings generator for CI (no derivations, cross-platform)
      # Reads permissions from unified ai-assistant-instructions structure
      ciClaudeSettings =
        let
          # Import unified permissions using the common module
          # Minimal config for CI - only needs lib and placeholder homeDir
          aiCommon = import ./modules/home-manager/ai-cli/common {
            inherit ai-assistant-instructions;
            inherit (nixpkgs) lib;
            config = {
              home.homeDirectory = "/home/user"; # Placeholder for CI
            };
          };
          inherit (aiCommon) permissions;
          inherit (aiCommon) formatters;
        in
        import ./lib/claude-settings.nix {
          inherit (nixpkgs) lib; # Required for pure evaluation
          homeDir = "/home/user"; # Placeholder - CI only validates schema structure
          schemaUrl = userConfig.ai.claudeSchemaUrl;
          permissions = {
            allow = formatters.claude.formatAllowed permissions;
            deny = formatters.claude.formatDenied permissions;
            ask = [ ]; # No ask permissions defined yet
          };
          plugins =
            (import ./modules/home-manager/ai-cli/claude-plugins.nix {
              inherit
                claude-code-plugins
                claude-cookbooks
                claude-plugins-official
                anthropic-skills
                claude-code-workflows
                claude-skills
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
          superpowers-marketplace
          jacobpevans-cc-plugins
          claude-code-workflows
          claude-skills
          ;
      };
      # Define configuration once, assign to multiple names
      darwinConfig = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/macbook-m4/default.nix

          # mac-app-util: Creates trampolines for system-level apps (/Applications/Nix Apps/)
          mac-app-util.darwinModules.default

          home-manager.darwinModules.home-manager
          {
            home-manager = hmDefaults // {
              inherit extraSpecialArgs;
              users.${userConfig.user.name} = import ./hosts/macbook-m4/home.nix;

              # Agent OS: Proper home-manager module for spec-driven AI development
              # Claude: Unified configuration for Claude Code ecosystem
              # Monitoring: K8s-based observability stack (OTEL, Cribl, Splunk)
              # Note: nix-config-symlink module intentionally removed.
              # It conflicted with ~/.config/nix being a git worktree.
              # See PLANNING-monitoring.md for details.
              #
              # NOTE: mac-app-util home-manager module REMOVED - using copyApps instead.
              # copyApps copies apps to ~/Applications/Home Manager Apps/ with stable paths,
              # making mac-app-util trampolines redundant for TCC permission persistence.
              # The darwin-level mac-app-util module is still used for /Applications/Nix Apps/.
              sharedModules = [
                ./modules/home-manager/ai-cli/agent-os
                ./modules/home-manager/ai-cli/claude
                ./modules/monitoring
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
