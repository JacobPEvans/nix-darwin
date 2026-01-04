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
  jacobpevans-cc-plugins,
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
  # Excludes high-token commands to reduce context bloat
  discoverCommands =
    dir:
    let
      files = if builtins.pathExists dir then builtins.readDir dir else { };
      mdFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) files;
    in
    map (name: lib.removeSuffix ".md" name) (builtins.attrNames mdFiles);

  # Commands to EXCLUDE from auto-discovery (high token cost)
  # These can still be used via /skill if needed
  excludedCommands = [
    "auto-claude" # Very large, not actively used due to token issues
    "shape-issues" # Should be a plugin, not a command
    "consolidate-issues" # Large, rarely used
    "init-change" # Deprecated, replaced by init-worktree
  ];

  # Commands from agentsmd (Nix store / flake input)
  # Auto-discovers all .md files in agentsmd/commands/ (minus excluded)
  agentsMdCommands = lib.filter (cmd: !(builtins.elem cmd excludedCommands)) (
    discoverCommands "${ai-assistant-instructions}/agentsmd/commands"
  );

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
  # ENABLED - Uses Haiku model for cost-efficiency (set via ANTHROPIC_MODEL env var)
  # Resource limits: max 10 PRs, max 50 issues, max 1 analysis per item per run
  autoClaude = {
    enable = true;
    repositories = {
      # ai-assistant-instructions: every 4 hours starting at midnight
      # Uses local repo (not Nix store) because autoClaude needs writable git
      # Schedule: 0, 4, 8, 12, 16, 20 (6 times/day)
      ai-assistant-instructions = {
        enabled = true;
        path = autoClaudeLocalRepoPath;
        schedule.hours = lib.lists.genList (i: i * 4) 6;
        maxBudget = 20.0;
      };
      # nix config: every 4 hours starting at 1am (offset +1 to prevent concurrent runs)
      # Schedule: 1, 5, 9, 13, 17, 21 (6 times/day)
      nix = {
        enabled = true;
        path = "${config.home.homeDirectory}/.config/nix";
        schedule.hours = lib.lists.genList (i: i * 4 + 1) 6;
        maxBudget = 20.0;
      };
      # terraform-proxmox: every 4 hours starting at 2am (offset +2 to prevent concurrent runs)
      # Schedule: 2, 6, 10, 14, 18, 22 (6 times/day)
      terraform-proxmox = {
        enabled = true;
        path = "${config.home.homeDirectory}/git/terraform-proxmox/main";
        schedule.hours = lib.lists.genList (i: i * 4 + 2) 6;
        maxBudget = 20.0;
      };
    };

    # Reporting: Twice-daily utilization reports and real-time anomaly alerts
    reporting = {
      enable = true;

      # Scheduled digest reports (8am and 5pm EST)
      scheduledReports = {
        times = [
          "08:00"
          "17:00"
        ]; # 8am and 5pm EST
        slackChannel = ""; # Retrieve from BWS at runtime
      };

      # Real-time anomaly detection
      alerts = {
        enable = true;
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
    # Marketplaces from modular configuration with flakeInput for Nix symlinks
    # See: modules/home-manager/ai-cli/claude/plugins/marketplaces.nix
    # Adding flakeInput enables Nix to create immutable symlinks instead of runtime downloads
    marketplaces =
      let
        # Map marketplace names to flake inputs for Nix-managed symlinks
        # Using a lookup table for better maintainability and readability
        # Keys MUST match marketplace.nix keys exactly
        flakeInputMap = {
          "jacobpevans-cc-plugins" = jacobpevans-cc-plugins; # User's personal plugins (listed first in marketplaces.nix)
          "claude-plugins-official" = claude-plugins-official;
          "superpowers-marketplace" = superpowers-marketplace;
          "anthropic-agent-skills" = anthropic-skills;
        };
      in
      lib.mapAttrs (
        name: marketplace:
        let
          flakeInput = flakeInputMap.${name} or null;
        in
        marketplace // lib.optionalAttrs (flakeInput != null) { inherit flakeInput; }
      ) claudePlugins.pluginConfig.marketplaces;

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
      # Model selection: Haiku is default for cost-efficiency and speed.
      # Override with /model command in interactive sessions if needed.
      ANTHROPIC_MODEL = "haiku"; # Default model for all sessions and auto-claude.
      CLAUDE_CODE_SUBAGENT_MODEL = "claude-haiku-4-5-20251001"; # Force haiku for sub-agents.
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

  # MCPs disabled - token cost too high for context window
  # Can be re-enabled by adding entries like:
  # mcpServers = {
  #   bitwarden = {
  #     command = "${config.home.homeDirectory}/.npm-packages/bin/mcp-server-bitwarden";
  #     args = [ ];
  #   };
  # };
  mcpServers = { };

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
