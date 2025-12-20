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
  superpowers-marketplace,
  ...
}:

let
  userConfig = import ../../../lib/user-config.nix;

  # Local repo path - ONLY used for autoClaude (needs writable git for commits)
  # All other ai-assistant-instructions content comes from Nix store (flake input)
  autoClaudeLocalRepoPath = userConfig.ai.instructionsRepo;

  # Read permissions from ai-assistant-instructions
  # Helper to reduce repetition (DRY)
  readPermissionsJson = path: builtins.fromJSON (builtins.readFile path);

  claudeAllowJson = readPermissionsJson "${ai-assistant-instructions}/.claude/permissions/allow.json";
  claudeAskJson = readPermissionsJson "${ai-assistant-instructions}/.claude/permissions/ask.json";
  claudeDenyJson = readPermissionsJson "${ai-assistant-instructions}/.claude/permissions/deny.json";

  # Commands from agentsmd (Nix store / flake input)
  # Located in .claude/commands/
  # Note: "commit" removed - use /commit from commit-commands plugin instead
  agentsMdCommands = [
    "fix-all-pr-ci"
    "fix-pr-ci"
    "generate-code"
    "git-refresh"
    "infrastructure-review"
    "init-change"
    "init-worktree"
    "pr"
    "pr-review-feedback"
    "quick-add-permission"
    "review-code"
    "review-docs"
    "rok-manage-pr"
    "rok-resolve-issues"
    "rok-resolve-pr-review-thread"
    "rok-review-pr"
    "rok-shape-issues"
    "sync-main"
    "sync-main-all"
    "sync-permissions"
    "sync-prs-with-main"
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
  # Alternating schedule: one repo runs every hour
  autoClaude = {
    enable = true;
    repositories = {
      # ai-assistant-instructions: runs at even hours (0, 2, 4, ...)
      # Uses local repo (not Nix store) because autoClaude needs writable git
      ai-assistant-instructions = {
        path = autoClaudeLocalRepoPath;
        schedule.hours = lib.lists.genList (i: i * 2) 12;
        maxBudget = 25.0;
        # TODO: Configure Slack channel ID for this repo
        # slackChannel = "C_AI_INSTRUCTIONS";
      };
      # nix config: runs at odd hours (1, 3, 5, ...)
      nix = {
        path = "${config.home.homeDirectory}/.config/nix";
        schedule.hours = lib.lists.genList (i: i * 2 + 1) 12;
        maxBudget = 25.0;
        # TODO: Configure Slack channel ID for this repo
        # slackChannel = "C_NIX_CONFIG";
      };
    };
  };

  # Menu bar status indicator via SwiftBar
  menubar = {
    enable = true;
    refreshInterval = 30; # Update every 30 seconds
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
    # All commands from Nix store (flake inputs) for reproducibility
    fromFlakeInputs =
      # Commands from agentsmd (in .claude/commands/)
      (map (name: {
        inherit name;
        source = "${ai-assistant-instructions}/.claude/commands/${name}.md";
      }) agentsMdCommands)
      ++
        # Commands from claude-cookbooks
        (map (name: {
          inherit name;
          source = "${claude-cookbooks}/.claude/commands/${name}.md";
        }) cookbookCommands);
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
      # Model selection is dynamic (via /model command or shell env).
      # To set a default in this config, uncomment below.
      # ANTHROPIC_MODEL = "sonnet";  # Default model for new sessions.
      CLAUDE_CODE_SUBAGENT_MODEL = "claude-sonnet-4-5-20250929"; # For sub-agents; full model ID required
      # ANTHROPIC_DEFAULT_OPUS_MODEL = "";
      # ANTHROPIC_DEFAULT_SONNET_MODEL = "";
      # ANTHROPIC_DEFAULT_HAIKU_MODEL = "";

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
      # Disabled: upstream repository no longer available (404)
      # Repository: https://github.com/rz1989s/claude-code-statusline
      enable = false;
      # Full config for local terminal
      # configFile = statuslineConfigFull;
      # Mobile config for SSH sessions (single-line, minimal)
      # mobileConfigFile = statuslineConfigMobile;
    };
  };
}
