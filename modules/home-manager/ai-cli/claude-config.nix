# Claude Code Configuration Values
#
# Centralized configuration for the programs.claude module.
# Imported by common.nix to keep it clean and high-level.
{
  config,
  lib,
  claude-code-plugins,
  claude-cookbooks,
  claude-plugins-official,
  anthropic-skills,
  ai-assistant-instructions,
  superpowers-marketplace,
  jacobpevans-cc-plugins,
  claude-code-workflows,
  claude-skills,
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

  # Dynamic discovery helper - finds all .md files in a directory
  discoverMarkdownFiles =
    dir:
    let
      files = if builtins.pathExists dir then builtins.readDir dir else { };
      mdFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) files;
    in
    map (name: lib.removeSuffix ".md" name) (builtins.attrNames mdFiles);

  # Discover items from both ai-assistant-instructions and claude-cookbooks
  # Used for both commands and agents
  discoveredItems = {
    cbCommands = discoverMarkdownFiles "${claude-cookbooks}/.claude/commands";
    aiAgents = discoverMarkdownFiles "${ai-assistant-instructions}/agentsmd/agents";
    cbAgents = discoverMarkdownFiles "${claude-cookbooks}/.claude/agents";
  };

  inherit (discoveredItems)
    cbCommands
    aiAgents
    cbAgents
    ;

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
      claude-code-workflows
      claude-skills
      ;
  };

  # Extract enabled plugins from modular configuration
  inherit (claudePlugins.pluginConfig) enabledPlugins;

  # Helper to build command/agent entries from discovered names
  mkSourceEntries =
    sourcePath: names:
    map (name: {
      inherit name;
      source = "${sourcePath}/${name}.md";
    }) names;

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

  # Agent teams display mode (direct settings.json property)
  teammateMode = "auto";

  # Auto-Claude: Scheduled autonomous maintenance
  # ENABLED - Uses Haiku model for cost-efficiency (via per-repo CLAUDE_MODEL env var)
  # Interactive sessions use the default model, autoClaude overrides to Haiku
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
        schedule.times = map (hour: {
          inherit hour;
          minute = 0;
        }) (lib.lists.genList (i: i * 4) 6);
        maxBudget = 20.0;
      };
      # nix config: every 4 hours starting at 1am (offset +1 to prevent concurrent runs)
      # Schedule: 1, 5, 9, 13, 17, 21 (6 times/day)
      nix = {
        enabled = true;
        path = "${config.home.homeDirectory}/.config/nix";
        schedule.times = map (hour: {
          inherit hour;
          minute = 0;
        }) (lib.lists.genList (i: i * 4 + 1) 6);
        maxBudget = 20.0;
      };
      # terraform-proxmox: every 4 hours starting at 2am (offset +2 to prevent concurrent runs)
      # Schedule: 2, 6, 10, 14, 18, 22 (6 times/day)
      terraform-proxmox = {
        enabled = true;
        path = "${config.home.homeDirectory}/git/terraform-proxmox/main";
        schedule.times = map (hour: {
          inherit hour;
          minute = 0;
        }) (lib.lists.genList (i: i * 4 + 2) 6);
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
    fromFlakeInputs = mkSourceEntries "${claude-cookbooks}/.claude/commands" cbCommands;
  };

  agents.fromFlakeInputs =
    (mkSourceEntries "${ai-assistant-instructions}/agentsmd/agents" aiAgents)
    ++ (mkSourceEntries "${claude-cookbooks}/.claude/agents" cbAgents);

  settings = {
    # Extended thinking enabled with token budget controlled via env vars
    alwaysThinkingEnabled = true;

    # Session cleanup (upstream default is 30)
    cleanupPeriodDays = 14;

    # Environment variables for model config and token optimization
    # See: https://code.claude.com/docs/en/settings
    # See: https://code.claude.com/docs/en/model-config
    env = {
      # Model selection: Sonnet is default for interactive sessions (better reasoning).
      # Use `opusplan` alias for complex tasks (Opus for planning, Sonnet for execution).
      # Auto-claude background jobs use their own CLAUDE_MODEL env var (haiku).
      # ANTHROPIC_MODEL = "sonnet"; # Uncomment to override default model
      # CLAUDE_CODE_SUBAGENT_MODEL = "claude-haiku-4-5-20251001"; # Cost control for subagents

      # Explicit model versions (Jan 2026) - pin to known working versions if customization needed
      # ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-4-5-20251101";
      # ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4-5-20250929";
      # ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-4-5-20251001";

      # MCP timeout settings (5 minutes) - required for PAL MCP complex operations
      MCP_TIMEOUT = "300000";
      MCP_TOOL_TIMEOUT = "300000";

      # Experimental: Agent teams - coordinate multiple Claude Code instances
      # See: https://code.claude.com/docs/en/agent-teams
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";

      # DEFAULT VALUES - do not remove, reference only
      # These are commented out because they match upstream defaults.
      # Kept for reference in case adjustments are needed in the future.
      # Extended thinking (enabled via alwaysThinkingEnabled setting)
      # Note: reduces prompt caching efficiency
      # MAX_THINKING_TOKENS = "16384";
      # CLAUDE_CODE_MAX_OUTPUT_TOKENS = "16384";
      # BASH_MAX_OUTPUT_LENGTH = "65536";
      # MAX_MCP_OUTPUT_TOKENS = "25000";
      # SLASH_COMMAND_TOOL_CHAR_BUDGET = "16000";
      # BASH_DEFAULT_TIMEOUT_MS = "300000";  # 5 minutes
      # BASH_MAX_TIMEOUT_MS = "600000";  # 10 minutes
    };

    # Permissions from unified ai-assistant-instructions system
    # Uses common/permissions.nix which reads from agentsmd/permissions/
    # Formatted by common/formatters.nix to Claude Code format
    permissions = {
      allow = formatters.claude.formatAllowed permissions;
      deny = formatters.claude.formatDenied permissions;
      ask = formatters.claude.formatAsk permissions;
    };

    # Additional directories accessible to Claude Code without prompts
    additionalDirectories = [
      "~/"
      "~/.claude/"
      "~/.config/"
    ];

    # Sandbox configuration (Dec 2025 feature)
    # Provides filesystem/network isolation when working in untrusted codebases.
    # Currently disabled - enable when reviewing external code or untrusted repos.
    sandbox = {
      enabled = false;
      autoAllowBashIfSandboxed = true; # Safe because sandbox prevents destructive ops
      excludedCommands = [
        "git"
        "nix"
        "darwin-rebuild"
      ];
    };
  };

  # MCP Servers - NOT managed via settings.json
  # Claude Code reads MCP servers from ~/.claude.json (user scope) or .mcp.json (project scope)
  # Use CLI to add servers: `claude mcp add --scope user --transport stdio <name> -- <command> [args]`
  #
  # Pre-configured servers (add manually via CLI):
  #   claude mcp add --scope user --transport stdio pal -- uvx --from "git+https://github.com/BeehiveInnovations/pal-mcp-server.git" pal-mcp-server
  #   claude mcp add --scope user --transport stdio github -- github-mcp-server stdio
  #   claude mcp add --scope user --transport stdio terraform -- terraform-mcp-server stdio
  #
  # API Keys: Servers requiring API keys (github, pal) work with d-claude alias
  # which injects secrets from Doppler (ai-ci-automation project)

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
