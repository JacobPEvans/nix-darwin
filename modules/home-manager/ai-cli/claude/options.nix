# Claude Code Module Options
#
# All configuration options for the unified Claude Code module.
# Cross-platform: no Darwin-specific code here.
{ lib, ... }:

with lib;

let
  # Reusable submodule types
  marketplaceModule = types.submodule {
    options = {
      source = mkOption {
        type = types.submodule {
          options = {
            type = mkOption {
              type = types.enum [ "git" "github" "local" ];
              default = "git";
            };
            url = mkOption { type = types.str; };
          };
        };
      };
      flakeInput = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Flake input for Nix-managed (immutable) plugins";
      };
    };
  };

  componentModule = types.submodule {
    options = {
      name = mkOption { type = types.str; };
      source = mkOption { type = types.path; };
    };
  };

  mcpServerModule = types.submodule {
    options = {
      command = mkOption { type = types.str; };
      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
      };
      disabled = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  hookType = types.nullOr (types.either types.path types.lines);

in {
  options.programs.claude = {
    enable = mkEnableOption "Claude Code configuration";

    # Plugins
    plugins = {
      marketplaces = mkOption {
        type = types.attrsOf marketplaceModule;
        default = { };
      };
      enabled = mkOption {
        type = types.attrsOf types.bool;
        default = { };
      };
      allowRuntimeInstall = mkOption {
        type = types.bool;
        default = true;
      };
    };

    # Commands
    commands = {
      fromFlakeInputs = mkOption {
        type = types.listOf componentModule;
        default = [ ];
      };
      local = mkOption {
        type = types.attrsOf types.path;
        default = { };
      };
      fromLiveRepo = mkOption {
        type = types.nullOr types.path;
        default = null;
      };
      liveRepoCommands = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };

    # Agents
    agents = {
      fromFlakeInputs = mkOption {
        type = types.listOf componentModule;
        default = [ ];
      };
      local = mkOption {
        type = types.attrsOf types.path;
        default = { };
      };
    };

    # Skills
    skills = {
      fromFlakeInputs = mkOption {
        type = types.listOf componentModule;
        default = [ ];
      };
      local = mkOption {
        type = types.attrsOf types.path;
        default = { };
      };
    };

    # Hooks (Phase 2 - not yet implemented)
    # These options are declared for future hook support.
    # Implementation will generate ~/.claude/hooks/ scripts.
    hooks = {
      preToolUse = mkOption {
        type = hookType;
        default = null;
      };
      postToolUse = mkOption {
        type = hookType;
        default = null;
      };
      userPromptSubmit = mkOption {
        type = hookType;
        default = null;
      };
      stop = mkOption {
        type = hookType;
        default = null;
      };
      subagentStop = mkOption {
        type = hookType;
        default = null;
      };
      sessionStart = mkOption {
        type = hookType;
        default = null;
      };
      sessionEnd = mkOption {
        type = hookType;
        default = null;
      };
    };

    # MCP Servers
    mcpServers = mkOption {
      type = types.attrsOf mcpServerModule;
      default = { };
    };

    # API Key Helper (for headless authentication)
    apiKeyHelper = {
      enable = mkEnableOption "API key helper for headless Claude authentication";

      scriptPath = mkOption {
        type = types.str;
        default = ".local/bin/claude-api-key-helper";
        description =
          "Path (relative to home) where the API key helper script is installed";
      };

      keychainService = mkOption {
        type = types.str;
        default = "bws-claude-automation";
        description = "Keychain service name for the BWS access token";
      };

      secretId = mkOption {
        type = types.str;
        description = "Bitwarden secret ID for the Claude OAuth token";
      };
    };

    # Settings
    settings = {
      alwaysThinkingEnabled = mkOption {
        type = types.bool;
        default = true;
      };
      permissions = {
        allow = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
        deny = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
        ask = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
      };
      additionalDirectories = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      schemaUrl = mkOption {
        type = types.str;
        default = "https://json.schemastore.org/claude-code-settings.json";
      };
    };

    # Status Line (supports claude-code-statusline)
    statusLine = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      script = mkOption {
        type = types.nullOr types.lines;
        default = null;
      };
      enhanced = {
        enable = mkOption {
          type = types.bool;
          default = false;
        };
        source = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Flake input path to claude-code-statusline repo";
        };
        configFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description =
            "Path to Config.toml for local/full display (defaults to examples/Config.toml from source)";
        };
        mobileConfigFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description =
            "Path to minimal Config.toml for SSH/mobile terminals (single-line display)";
        };
        # Internal: package built by statusline.nix, used by settings.nix
        package = mkOption {
          type = types.nullOr types.package;
          default = null;
          internal = true;
          description = "Internal: built statusline package";
        };
      };
    };

    # Feature Flags
    features = {
      pluginSchemaVersion = mkOption {
        type = types.int;
        default = 1;
      };
      experimental = mkOption {
        type = types.attrsOf types.bool;
        default = { };
      };
    };
  };
}
