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
              type = types.enum [
                "git"
                "github"
                "local"
              ];
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

in
{
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
        description = "Path (relative to home) where the API key helper script is installed";
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
      # Extended thinking mode
      alwaysThinkingEnabled = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable Claude's extended thinking capability by default.
          When enabled, Claude can reason through complex problems step-by-step.
          Token budget controlled by MAX_THINKING_TOKENS in env.
        '';
      };

      # Session management
      cleanupPeriodDays = mkOption {
        type = types.int;
        default = 14;
        description = ''
          Sessions inactive longer than this period are deleted.
          Default upstream is 30, we use 14 to reduce storage.
        '';
      };

      # Permissions
      permissions = {
        allow = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Commands and operations to auto-approve without prompting";
        };
        deny = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Commands and operations to permanently block";
        };
        ask = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Commands and operations requiring user confirmation";
        };
      };

      additionalDirectories = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Directories accessible to Claude Code without prompts";
      };

      # Environment variables for Claude Code
      # See: https://code.claude.com/docs/en/settings
      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = ''
          Environment variables passed to Claude Code.
          Common variables:
          - MAX_THINKING_TOKENS: Extended thinking token budget (e.g., "16000")
          - CLAUDE_CODE_MAX_OUTPUT_TOKENS: Max output tokens (e.g., "16000")
          - BASH_MAX_OUTPUT_LENGTH: Max bash output chars (e.g., "64000")
          - BASH_DEFAULT_TIMEOUT_MS: Default bash timeout (e.g., "120000")
          - DISABLE_PROMPT_CACHING: Disable caching ("1" to disable)
        '';
        example = {
          MAX_THINKING_TOKENS = "16000";
          CLAUDE_CODE_MAX_OUTPUT_TOKENS = "16000";
        };
      };

      schemaUrl = mkOption {
        type = types.str;
        default = "https://json.schemastore.org/claude-code-settings.json";
        description = "JSON schema URL for settings validation";
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
          description = "Path to Config.toml for local/full display (defaults to examples/Config.toml from source)";
        };
        mobileConfigFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to minimal Config.toml for SSH/mobile terminals (single-line display)";
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
