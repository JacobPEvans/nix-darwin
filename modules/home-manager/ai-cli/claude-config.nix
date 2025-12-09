# Claude Code Configuration Values
#
# Centralized configuration for the programs.claude module.
# Imported by common.nix to keep it clean and high-level.
{ config, pkgs, lib, claude-code-plugins, claude-cookbooks, claude-plugins-official
, anthropic-skills, ai-assistant-instructions, ... }:

let
  userConfig = import ../../../lib/user-config.nix;
  aiInstructionsRepo = userConfig.ai.instructionsRepo;

  # Read permissions from ai-assistant-instructions
  claudeAllowJson = builtins.fromJSON
    (builtins.readFile "${ai-assistant-instructions}/.claude/permissions/allow.json");
  claudeAskJson = builtins.fromJSON
    (builtins.readFile "${ai-assistant-instructions}/.claude/permissions/ask.json");
  claudeDenyJson = builtins.fromJSON
    (builtins.readFile "${ai-assistant-instructions}/.claude/permissions/deny.json");

  # Commands from ai-assistant-instructions repo (live updates)
  liveRepoCommands = [
    "commit"
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
  cookbookCommands = [
    "review-pr-ci"
    "review-pr"
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

    # Experimental (uncomment to enable)
    # "ralph-wiggum@anthropics/claude-code" = true;  # Autonomous iteration loops
  };

in {
  enable = true;

  plugins = {
    marketplaces = {
      "anthropics/claude-code" = {
        source = { type = "git"; url = "https://github.com/anthropics/claude-code.git"; };
        flakeInput = claude-code-plugins;
      };
      "anthropics/claude-plugins-official" = {
        source = { type = "git"; url = "https://github.com/anthropics/claude-plugins-official.git"; };
        flakeInput = claude-plugins-official;
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
    permissions = {
      allow = claudeAllowJson.permissions;
      deny = claudeDenyJson.permissions;
      ask = claudeAskJson.permissions;
    };

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
    # Script reads JSON from stdin and outputs status line
    # Uses jq and git which must be in PATH (installed system-wide)
    script = builtins.readFile (./. + "/statusline.sh");
  };
}
