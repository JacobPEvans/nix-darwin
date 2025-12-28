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

  # Import unified permissions from common module
  # This reads from ai-assistant-instructions agentsmd/permissions/
  aiCommon = import ./common { inherit lib config ai-assistant-instructions; };
  inherit (aiCommon) permissions;
  inherit (aiCommon) formatters;

  # Dynamic command discovery from flake inputs
  # No more hardcoded lists - discovers all .md files automatically
  discoverCommands =
    dir:
    let
      files = if builtins.pathExists dir then builtins.readDir dir else { };
      mdFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) files;
    in
    map (name: lib.removeSuffix ".md" name) (builtins.attrNames mdFiles);

  # Commands from agentsmd (Nix store / flake input)
  # Auto-discovers all .md files in agentsmd/commands/
  agentsMdCommands = discoverCommands "${ai-assistant-instructions}/agentsmd/commands";

  # Commands from claude-cookbooks (immutable from flake)
  # Auto-discovers all .md files in .claude/commands/
  cookbookCommands = discoverCommands "${claude-cookbooks}/.claude/commands";

  # Agents from claude-cookbooks
  # Auto-discovers all .md files in .claude/agents/
  cookbookAgents = discoverCommands "${claude-cookbooks}/.claude/agents";

  # Import modular plugin configuration
  # Plugin configuration moved to claude-plugins.nix and organized by category
  # See: modules/home-manager/ai-cli/claude/plugins/*.nix
  claudePlugins = import ./claude-plugins.nix {
    inherit
      config
      lib
      claude-code-plugins
      claude-cookbooks
      claude-plugins-official
      anthropic-skills
      ;
  };

  # Extract enabled plugins from modular configuration
  inherit (claudePlugins.pluginConfig) enabledPlugins;

in
{
  enable = true;

  # API Key Helper for headless authentication (cron jobs, CI/CD)
  # Uses Bitwarden Secrets Manager to securely fetch OAuth token
  # Configuration: ~/.config/bws/.env (see bws-env.example)
  apiKeyHelper = {
    enable = true;
    # scriptPath default: .local/bin/claude-api-key-helper
  };

  # Auto-Claude: Scheduled autonomous maintenance
  # ENABLED - Uses Sonnet model only (--model sonnet enforced in auto-claude.sh)
  # Resource limits: max 10 PRs, max 50 issues, max 1 analysis per item per run
  autoClaude = {
    enable = true;
    repositories = {
      # ai-assistant-instructions: disabled (was running at even hours)
      # Uses local repo (not Nix store) because autoClaude needs writable git
      ai-assistant-instructions = {
        enabled = false;
        path = autoClaudeLocalRepoPath;
        schedule.hours = [ ]; # Empty schedule - no runs
        maxBudget = 20.0;
      };
      # nix config: disabled (was running at odd hours)
      nix = {
        enabled = false;
        path = "${config.home.homeDirectory}/.config/nix";
        schedule.hours = [ ]; # Empty schedule - no runs
        maxBudget = 20.0;
      };
    };

    # Reporting: Twice-daily utilization reports and real-time anomaly alerts
    reporting = {
      enable = false;

      # Scheduled digest reports (disabled)
      scheduledReports = {
        times = [ ]; # Empty - no scheduled reports
        slackChannel = ""; # Retrieve from BWS when re-enabled
      };

      # Real-time anomaly detection
      alerts = {
        enable = false;
        contextThreshold = 90;
        budgetThreshold = 50;
        tokensNoOutput = 50000;
        consecutiveFailures = 2;
      };
    };
  };

  # Menu bar status indicator via SwiftBar
  menubar = {
    enable = true;
    refreshInterval = 30; # Update every 30 seconds
  };

  plugins = {
    # Marketplaces from modular configuration
    # See: modules/home-manager/ai-cli/claude/plugins/marketplaces.nix
    inherit (claudePlugins.pluginConfig) marketplaces;

    enabled = enabledPlugins;
    # Enable runtime plugin installation from community marketplaces.
    # Nix defines the baseline (official plugins via flake inputs).
    # Claude can dynamically install additional plugins at runtime.
    # Runtime state tracked in ~/.claude/plugins/installed_plugins.json (not Nix-managed).
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
      # CLAUDE_CODE_SUBAGENT_MODEL = "claude-sonnet-4-5-20250929"; # For sub-agents; full model ID required. Left disabled to use orchestrator defaults; uncomment only to force a specific sub-agent model.
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

    # Permissions from unified ai-assistant-instructions system
    # Uses common/permissions.nix which reads from agentsmd/permissions/
    # Formatted by common/formatters.nix to Claude Code format
    permissions = {
      allow = formatters.claude.formatAllowed permissions;
      deny = formatters.claude.formatDenied permissions;
      ask = [ ]; # No ask permissions defined yet
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
