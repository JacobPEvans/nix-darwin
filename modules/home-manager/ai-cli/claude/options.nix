# Claude Code Module Options
#
# All configuration options for the unified Claude Code module.
# Cross-platform: no Darwin-specific code here.
{ lib, ... }:

let
  # Reusable submodule types
  marketplaceModule = types.submodule {
    options = {
      source = lib.mkOption {
        type = types.submodule {
          options = {
            type = lib.mkOption {
              type = types.enum [
                "git"
                "github"
                "local"
              ];
              default = "git";
            };
            url = lib.mkOption { type = types.str; };
          };
        };
      };
      flakeInput = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Flake input for Nix-managed (immutable) plugins";
      };
    };
  };

  componentModule = types.submodule {
    options = {
      name = lib.mkOption { type = types.str; };
      source = lib.mkOption { type = types.path; };
    };
  };

  mcpServerModule = types.submodule {
    options = {
      command = lib.mkOption { type = types.str; };
      args = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      env = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
      };
      disabled = lib.mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  hookType = types.nullOr (types.either types.path types.lines);

in
{
  options.programs.claude = {
    enable = lib.mkEnableOption "Claude Code configuration";

    # Plugins
    plugins = {
      marketplaces = lib.mkOption {
        type = types.attrsOf marketplaceModule;
        default = { };
      };
      enabled = lib.mkOption {
        type = types.attrsOf types.bool;
        default = { };
      };
      allowRuntimeInstall = lib.mkOption {
        type = types.bool;
        default = true;
      };
    };

    # Commands
    commands = {
      fromFlakeInputs = lib.mkOption {
        type = types.listOf componentModule;
        default = [ ];
      };
      local = lib.mkOption {
        type = types.attrsOf types.path;
        default = { };
      };
      fromLiveRepo = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
      };
      liveRepoCommands = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };

    # Agents
    agents = {
      fromFlakeInputs = lib.mkOption {
        type = types.listOf componentModule;
        default = [ ];
      };
      local = lib.mkOption {
        type = types.attrsOf types.path;
        default = { };
      };
    };

    # Skills
    skills = {
      fromFlakeInputs = lib.mkOption {
        type = types.listOf componentModule;
        default = [ ];
      };
      local = lib.mkOption {
        type = types.attrsOf types.path;
        default = { };
      };
    };

    # Hooks (Phase 2 - not yet implemented)
    # These options are declared for future hook support.
    # Implementation will generate ~/.claude/hooks/ scripts.
    hooks = {
      preToolUse = lib.mkOption {
        type = hookType;
        default = null;
      };
      postToolUse = lib.mkOption {
        type = hookType;
        default = null;
      };
      userPromptSubmit = lib.mkOption {
        type = hookType;
        default = null;
      };
      stop = lib.mkOption {
        type = hookType;
        default = null;
      };
      subagentStop = lib.mkOption {
        type = hookType;
        default = null;
      };
      sessionStart = lib.mkOption {
        type = hookType;
        default = null;
      };
      sessionEnd = lib.mkOption {
        type = hookType;
        default = null;
      };
    };

    # MCP Servers
    mcpServers = lib.mkOption {
      type = types.attrsOf mcpServerModule;
      default = { };
    };

    # API Key Helper (for headless authentication)
    #
    # This feature assumes you have created a ~/.config/bws/.env file
    # containing the required environment variables for Bitwarden/Claude
    # API key retrieval. Configuration is not provided via Nix options.
    #
    # NOTE: The bws_helper.py script currently performs little or no
    # validation of this file. If ~/.config/bws/.env is missing or
    # misconfigured, the helper will fail at runtime with confusing
    # errors rather than clear setup instructions.
    #
    # Before enabling this option, ensure that:
    #   - ~/.config/bws/.env exists
    #   - it contains all variables expected by bws_helper.py
    #   - the file has appropriate permissions (not world-readable)
    apiKeyHelper = {
      enable = lib.mkEnableOption "API key helper for headless Claude authentication";

      scriptPath = lib.mkOption {
        type = types.str;
        default = ".local/bin/claude-api-key-helper";
        description = "Path (relative to home) where the API key helper script is installed";
      };
    };

    # Settings
    settings = {
      # Extended thinking mode
      alwaysThinkingEnabled = lib.mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable Claude's extended thinking capability by default.
          When enabled, Claude can reason through complex problems step-by-step.
          Token budget controlled by MAX_THINKING_TOKENS in env.
        '';
      };

      # Session management
      cleanupPeriodDays = lib.mkOption {
        type = types.int;
        default = 14;
        description = ''
          Sessions inactive longer than this period are deleted.
          Default upstream is 30, we use 14 to reduce storage.
        '';
      };

      # Permissions
      permissions = {
        allow = lib.mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Commands and operations to auto-approve without prompting";
        };
        deny = lib.mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Commands and operations to permanently block";
        };
        ask = lib.mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Commands and operations requiring user confirmation";
        };
      };

      additionalDirectories = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Directories accessible to Claude Code without prompts";
      };

      # Environment variables for Claude Code
      # See: https://code.claude.com/docs/en/settings
      env = lib.mkOption {
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

      schemaUrl = lib.mkOption {
        type = types.str;
        default = "https://json.schemastore.org/claude-code-settings.json";
        description = "JSON schema URL for settings validation";
      };
    };

    # Status Line (supports claude-code-statusline)
    statusLine = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
      };
      script = lib.mkOption {
        type = types.nullOr types.lines;
        default = null;
      };
      enhanced = {
        enable = lib.mkOption {
          type = types.bool;
          default = false;
        };
        source = lib.mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Flake input path to claude-code-statusline repo";
        };
        configFile = lib.mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to Config.toml for local/full display (defaults to examples/Config.toml from source)";
        };
        mobileConfigFile = lib.mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to minimal Config.toml for SSH/mobile terminals (single-line display)";
        };
        # Internal: package built by statusline.nix, used by settings.nix
        package = lib.mkOption {
          type = types.nullOr types.package;
          default = null;
          internal = true;
          description = "Internal: built statusline package";
        };
      };
    };

    # Feature Flags
    features = {
      pluginSchemaVersion = lib.mkOption {
        type = types.int;
        default = 1;
      };
      experimental = lib.mkOption {
        type = types.attrsOf types.bool;
        default = { };
      };
    };
  };
}
