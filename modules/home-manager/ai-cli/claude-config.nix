# Claude Code Configuration Values
#
# Centralized configuration for the programs.claude module.
# Imported by common.nix to keep it clean and high-level.
{
  config,
  pkgs,
  lib,
  claude-code-plugins,
  claude-cookbooks,
  claude-plugins-official,
  anthropic-skills,
  ai-assistant-instructions,
  claude-code-statusline,
  superpowers-marketplace,
  ...
}:

let
  userConfig = import ../../../lib/user-config.nix;
  aiInstructionsRepo = userConfig.ai.instructionsRepo;

  # Statusline configuration - flat TOML files (required format for statusline tool)
  # Full config for local terminal, mobile config for SSH sessions
  statuslineConfigFull = ./claude/statusline/config.toml;
  statuslineConfigMobile = ./claude/statusline/config-mobile.toml;

  # Read permissions from ai-assistant-instructions
  # Helper to reduce repetition (DRY)
  readPermissionsJson = path: builtins.fromJSON (builtins.readFile path);

  claudeAllowJson = readPermissionsJson "${ai-assistant-instructions}/.claude/permissions/allow.json";
  claudeAskJson = readPermissionsJson "${ai-assistant-instructions}/.claude/permissions/ask.json";
  claudeDenyJson = readPermissionsJson "${ai-assistant-instructions}/.claude/permissions/deny.json";

  # Commands from ai-assistant-instructions repo (live updates)
  # Note: "commit" removed - use /commit from commit-commands plugin instead
  liveRepoCommands = [
    "generate-code"
    "git-refresh"
    "infrastructure-review"
    "pull-request"
    "pull-request-review-feedback"
    "review-code"
    "review-docs"
    "rok-resolve-issues"
    "rok-respond-to-reviews"
    "rok-review-pr"
    "rok-shape-issues"
  ];

  # Commands from claude-cookbooks (immutable from flake)
  # Removed: "review-pr-ci", "review-pr" - replaced by code-review plugin (/code-review)
  cookbookCommands = [
    "review-issue"
    "notebook-review"
    "model-check"
    "link-review"
  ];

  # Agents from claude-cookbooks
  cookbookAgents = [ "code-reviewer" ];

  # Plugin enablement
  # See: https://github.com/anthropics/claude-code/tree/main/plugins
  enabledPlugins = {
    # Git workflow
    "commit-commands@anthropics/claude-code" = true;

    # Code review
    "code-review@anthropics/claude-code" = true;
    "pr-review-toolkit@anthropics/claude-code" = true;

    # Development workflow
    "feature-dev@anthropics/claude-code" = true;

    # Security
    "security-guidance@anthropics/claude-code" = true;

    # Plugin/hook development
    "plugin-dev@anthropics/claude-code" = true;
    "hookify@anthropics/claude-code" = true;

    # SDK development
    "agent-sdk-dev@anthropics/claude-code" = true;

    # UI/UX
    "frontend-design@anthropics/claude-code" = true;

    # Output styles
    "explanatory-output-style@anthropics/claude-code" = true;
    "learning-output-style@anthropics/claude-code" = true;

    # Migration tools
    "claude-opus-4-5-migration@anthropics/claude-code" = true;

    # Superpowers - comprehensive development workflow
    # Brainstorming, planning, execution, testing, and review skills
    "superpowers@obra/superpowers-marketplace" = true;

    # Experimental (uncomment to enable)
    # "ralph-wiggum@anthropics/claude-code" = true;  # Autonomous iteration loops
  };

in
{
  enable = true;

  # API Key Helper for headless authentication (cron jobs, CI/CD)
  # Uses Bitwarden Secrets Manager to securely fetch OAuth token
  apiKeyHelper = {
    enable = true;
    # scriptPath default: .local/bin/claude-api-key-helper
    # keychainService default: bws-claude-automation
    secretId = "55ebeb62-1327-4967-8f08-b3a5015f5b7b";
  };

  # Auto-Claude: Scheduled autonomous maintenance
  # Uses the main worktree, not ~/.config/nix (which is now a read-only symlink)
  autoClaude = {
    enable = true;
    repositories = {
      # ai-assistant-instructions: runs daily at 4am
      ai-assistant-instructions = {
        path = "${config.home.homeDirectory}/git/ai-assistant-instructions";
        schedule.times = [ { hour = 4; minute = 0; } ];
        maxBudget = 25.0;
      };
      # nix config: runs daily at 1pm (13:00) from the main worktree
      # ~/.config/nix is a read-only symlink to nix store
      nix = {
        path = "${config.home.homeDirectory}/git/nix-config/main";
        schedule.times = [ { hour = 13; minute = 0; } ];
        maxBudget = 25.0;
      };
    };
  };

  plugins = {
    marketplaces = {
      "anthropics/claude-code" = {
        source = {
          type = "git";
          url = "https://github.com/anthropics/claude-code.git";
        };
        flakeInput = claude-code-plugins;
      };
      "anthropics/claude-plugins-official" = {
        source = {
          type = "git";
          url = "https://github.com/anthropics/claude-plugins-official.git";
        };
        flakeInput = claude-plugins-official;
      };
      # Superpowers - comprehensive software development workflow system
      # https://github.com/obra/superpowers-marketplace
      "obra/superpowers-marketplace" = {
        source = {
          type = "git";
          url = "https://github.com/obra/superpowers-marketplace.git";
        };
        flakeInput = superpowers-marketplace;
      };
    };

    enabled = enabledPlugins;
    allowRuntimeInstall = true;
  };

  commands = {
    fromLiveRepo = aiInstructionsRepo;
    inherit liveRepoCommands;

    fromFlakeInputs = map (name: {
      inherit name;
      source = "${claude-cookbooks}/.claude/commands/${name}.md";
    }) cookbookCommands;
  };

  agents.fromFlakeInputs = map (name: {
    inherit name;
    source = "${claude-cookbooks}/.claude/agents/${name}.md";
  }) cookbookAgents;

  settings = {
    # Extended thinking enabled with token budget controlled via env vars
    alwaysThinkingEnabled = true;

    # Session cleanup (upstream default is 30)
    cleanupPeriodDays = 14;

    # Environment variables for model config and token optimization
    # See: https://code.claude.com/docs/en/settings
    # See: https://code.claude.com/docs/en/model-config
    env = {
      # Model selection - use defaults (Anthropic's latest recommended models)
      # As of Dec 2025, opus 4.5 is the default with token optimization
      # Slash commands can override with model: sonnet for cost-efficient tasks

      # Token budgets
      MAX_THINKING_TOKENS = "16384";
      CLAUDE_CODE_MAX_OUTPUT_TOKENS = "16384";
      BASH_MAX_OUTPUT_LENGTH = "65536";
      MAX_MCP_OUTPUT_TOKENS = "25000";
      SLASH_COMMAND_TOOL_CHAR_BUDGET = "16000";

      # Timeouts
      BASH_DEFAULT_TIMEOUT_MS = "300000";
      BASH_MAX_TIMEOUT_MS = "600000";
    };

    # Permissions from ai-assistant-instructions repo
    permissions = {
      allow = claudeAllowJson.permissions;
      deny = claudeDenyJson.permissions;
      ask = claudeAskJson.permissions;
    };

    # Additional directories accessible to Claude Code without prompts
    additionalDirectories = [
      "~/"
      "~/.claude/"
      "~/.config/"
    ];
  };

  mcpServers = {
    bitwarden = {
      command = "${config.home.homeDirectory}/.npm-packages/bin/mcp-server-bitwarden";
      args = [ ];
    };
  };

  statusLine = {
    enable = true;
    enhanced = {
      enable = true;
      # Pulls from flake input - auto-updated via Dependabot
      source = claude-code-statusline;
      # Full config for local terminal
      configFile = statuslineConfigFull;
      # Mobile config for SSH sessions (single-line, minimal)
      mobileConfigFile = statuslineConfigMobile;
    };
  };
}
