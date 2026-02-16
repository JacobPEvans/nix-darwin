{
  # Nix-darwin flake configuration
  description = "nix-darwin configuration for M4 Max MacBook Pro";

  inputs = {
    # Using stable nixpkgs-25.11 for reliability
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

    # Using unstable nixpkgs for faster updates to GUI apps
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

    # AI Assistant Instructions - source of truth for AI agent configuration
    # Contains permissions, commands, and instruction files
    # Consumed by claude.nix to generate settings.json
    # Tracks main branch for cutting-edge updates (user's own repo)
    ai-assistant-instructions = {
      url = "github:JacobPEvans/ai-assistant-instructions";
      flake = false; # Not a flake, just fetch the repo
    };

    # Marketplace Inputs (14 total)
    # Keys MUST match the `name` field in each repo's marketplace.json.
    # Adding a new marketplace: add input here, add to marketplaceInputs below, done.
    anthropic-agent-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
    bills-claude-skills = {
      url = "github:BillChirico/bills-claude-skills";
      flake = false;
    };
    cc-dev-tools = {
      url = "github:Lucklyric/cc-dev-tools";
      flake = false;
    };
    cc-marketplace = {
      url = "github:ananddtyagi/cc-marketplace";
      flake = false;
    };
    claude-code-plugins-plus = {
      url = "github:jeremylongshore/claude-code-plugins-plus";
      flake = false;
    };
    claude-code-workflows = {
      url = "github:wshobson/agents";
      flake = false;
    };
    claude-plugins-official = {
      url = "github:anthropics/claude-plugins-official";
      flake = false;
    };
    claude-skills = {
      url = "github:secondsky/claude-skills";
      flake = false;
    };
    jacobpevans-cc-plugins = {
      url = "github:JacobPEvans/claude-code-plugins";
      flake = false;
    };
    lunar-claude = {
      url = "github:basher83/lunar-claude";
      flake = false;
    };
    obsidian-skills = {
      url = "github:kepano/obsidian-skills";
      flake = false;
    };
    obsidian-visual-skills = {
      url = "github:axtonliu/axton-obsidian-visual-skills";
      flake = false;
    };
    superpowers-marketplace = {
      url = "github:obra/superpowers-marketplace";
      flake = false;
    };
    wakatime = {
      url = "github:wakatime/claude-code-wakatime";
      flake = false;
    };

  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      darwin,
      home-manager,
      mac-app-util,
      claude-code-plugins,
      claude-cookbooks,
      ai-assistant-instructions,
      # Marketplace inputs (all 14) - destructured individually for marketplaceInputs attrset
      anthropic-agent-skills,
      bills-claude-skills,
      cc-dev-tools,
      cc-marketplace,
      claude-code-plugins-plus,
      claude-code-workflows,
      claude-plugins-official,
      claude-skills,
      jacobpevans-cc-plugins,
      lunar-claude,
      obsidian-skills,
      obsidian-visual-skills,
      superpowers-marketplace,
      wakatime,
      ...
    }:
    let
      userConfig = import ./lib/user-config.nix;
      hmDefaults = import ./lib/home-manager-defaults.nix;

      # Import nixpkgs-unstable for faster updates to GUI applications
      unstablePkgs = import nixpkgs-unstable {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };

      # All 14 marketplace flake inputs as a single attrset.
      # Keys match manifest names in each repo's marketplace.json.
      # Adding a new marketplace: add flake input above, add to this set, done.
      marketplaceInputs = {
        inherit
          anthropic-agent-skills
          bills-claude-skills
          cc-dev-tools
          cc-marketplace
          claude-code-plugins-plus
          claude-code-workflows
          claude-plugins-official
          claude-skills
          jacobpevans-cc-plugins
          lunar-claude
          obsidian-skills
          obsidian-visual-skills
          superpowers-marketplace
          wakatime
          ;
      };

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
              inherit (nixpkgs) lib;
              inherit marketplaceInputs claude-cookbooks;
            }).pluginConfig;
        };

      # Pass external sources to home-manager modules
      extraSpecialArgs = {
        inherit
          unstablePkgs
          ai-assistant-instructions
          marketplaceInputs
          claude-cookbooks
          ;
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
                ./modules/home-manager/ai-cli/claude
                ./modules/home-manager/ai-cli/maestro
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
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            import ./lib/checks.nix {
              inherit pkgs;
              src = ./.;
            }
            // {
              # Validate CI settings JSON evaluates without errors
              # Catches missing flake inputs in the CI code path (separate from darwin-rebuild)
              ci-settings = pkgs.runCommand "check-ci-settings" { } ''
                echo ${nixpkgs.lib.escapeShellArg (builtins.toJSON ciClaudeSettings)} | ${pkgs.lib.getExe pkgs.jq} . > /dev/null
                touch $out
              '';
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
