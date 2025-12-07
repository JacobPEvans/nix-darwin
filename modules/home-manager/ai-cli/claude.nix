# Claude Code Configuration
#
# Returns home.file entries for Claude Code settings and status line.
# Imported by home.nix for clean separation of AI CLI configs.
#
# Strategy: Layered configuration approach
# 1. Nix manages settings.json (this file) - baseline approved commands
# 2. settings.local.json remains WRITABLE - for interactive "accept indefinitely"
# 3. Claude merges both: local overrides base
#
# Permissions: Read from JSON in ai-assistant-instructions repo
# - Centralized, portable permission definitions
# - Single source of truth across projects
#
# Plugins: Configured via claude-plugins.nix
# - Official Anthropic marketplace (claude-code repo)
# - Commands/agents from claude-cookbooks repo
#
# Commands: Symlinked from ai-assistant-instructions repo
# - rok-* community commands (Shape Up workflow)
# - Standard commands (commit, pull-request, etc.)

{ config, pkgs, lib, claude-code-plugins, claude-cookbooks, claude-plugins-official, anthropic-skills, ai-assistant-instructions, claude-code-settings-schema, ... }:

let
  # User configuration (includes ai.instructionsRepo path)
  userConfig = import ../../../lib/user-config.nix;

  # Read permissions from JSON files in ai-assistant-instructions
  # These are read at Nix evaluation time from the flake input
  #
  # Expected JSON structure for each file:
  # {
  #   "permissions": [
  #     "PermissionPattern1",
  #     "PermissionPattern2",
  #     ...
  #   ]
  # }
  #
  # If the file is missing, malformed, or lacks the "permissions" key,
  # Nix evaluation will fail with a descriptive error.
  readPermissionsJson = path:
    let
      json = builtins.fromJSON (builtins.readFile path);
    in
      if builtins.isAttrs json && json ? permissions
      then json
      else builtins.throw "Invalid permissions JSON at ${path}: must contain a 'permissions' key";

  claudeAllowJson = readPermissionsJson "${ai-assistant-instructions}/.claude/permissions/allow.json";
  claudeAskJson = readPermissionsJson "${ai-assistant-instructions}/.claude/permissions/ask.json";
  claudeDenyJson = readPermissionsJson "${ai-assistant-instructions}/.claude/permissions/deny.json";

  # Import plugin configuration (official Anthropic repos)
  claudePlugins = import ./claude-plugins.nix {
    inherit config lib claude-code-plugins claude-cookbooks claude-plugins-official anthropic-skills;
  };

  # Path to git repo for symlinks (live updates without rebuild)
  # Defined in lib/user-config.nix for DRY (also used by common.nix)
  aiInstructionsRepo = userConfig.ai.instructionsRepo;

  # Commands from ai-assistant-instructions to symlink globally
  # Using mkOutOfStoreSymlink for live updates without darwin-rebuild
  #
  # These commands live in .ai-instructions/commands/ and are symlinked
  # directly to ~/.claude/commands/ for global availability.
  aiInstructionsCommands = [
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

  # Create symlink entries for ai-instructions commands
  # Points directly to .ai-instructions/commands/ source files (not the .claude/commands/ symlinks)
  # This avoids a chain of symlinks and is more resilient
  mkAiInstructionsCommandSymlinks = builtins.listToAttrs (map (cmd: {
    name = ".claude/commands/${cmd}.md";
    value = {
      source = config.lib.file.mkOutOfStoreSymlink "${aiInstructionsRepo}/.ai-instructions/commands/${cmd}.md";
    };
  }) aiInstructionsCommands);

in
{
  # Claude Code settings.json
  ".claude/settings.json".text = builtins.toJSON {
    # NOTE: $schema removed - Claude Code doesn't recognize it and may break permissions
    # Schema symlink still available at ~/.claude/claude-code-settings.schema.json
    # for IDE IntelliSense (configure in editor, not in JSON)

    # Enable extended thinking mode
    alwaysThinkingEnabled = true;

    # Plugin marketplace configuration
    # Plugins are fetched on-demand from these marketplaces
    extraKnownMarketplaces = claudePlugins.pluginConfig.marketplaces;

    # Enabled plugins from marketplaces
    # See claude-plugins.nix for available plugins and descriptions
    enabledPlugins = claudePlugins.pluginConfig.enabledPlugins;

    # Auto-approved commands (from ai-assistant-instructions JSON)
    # Permissions are read from the flake input at build time
    permissions = {
      allow = claudeAllowJson.permissions;
      deny = claudeDenyJson.permissions;
      ask = claudeAskJson.permissions;

      # Directory-level read access
      # Grants Claude access to files outside the current working directory
      # This prevents "allow reading from X/" prompts for common locations
      additionalDirectories = [
        "~/"              # Full home directory access
        "~/.claude/"      # Claude configuration
        "~/.config/"      # XDG config directory
      ];
    };

    # Status line configuration
    statusLine = {
      type = "command";
      command = "${config.home.homeDirectory}/.claude/statusline-command.sh";
    };

    # MCP Servers
    #
    # Bitwarden MCP Server - provides Claude access to Bitwarden vault
    #
    # Security Model:
    #   - Dedicated machine account (NOT personal vault access)
    #   - Least privilege: only secrets the AI workflow requires
    #   - Short-lived session tokens (BW_SESSION expires on lock/timeout)
    #   - Credentials auto-rotated via Bitwarden Secrets Manager policies
    #
    # Setup:
    #   1. Install: npm install -g @bitwarden/mcp-server
    #   2. Unlock vault: bw unlock
    #   3. Export session: export BW_SESSION="<session_key>"
    #
    # Binary installed to ~/.npm-packages/bin via npm global prefix
    # (configured in modules/home-manager/npm/config.nix)
    mcpServers = {
      bitwarden = {
        command = "${config.home.homeDirectory}/.npm-packages/bin/mcp-server-bitwarden";
        args = [ ];
      };
    };
  };

  # Claude Code settings schema for IDE IntelliSense and validation
  # Community-built schema: https://github.com/spences10/claude-code-settings-schema
  # Used by: $schema reference in settings.json, pre-commit hooks, CI validation
  ".claude/claude-code-settings.schema.json".source =
    "${claude-code-settings-schema}/claude-code-settings.schema.json";

  # Claude Code status line script
  # Displays: robbyrussell-style prompt with directory, git status, model, and output style
  ".claude/statusline-command.sh" = {
    text = ''
      #!/bin/bash

      # Read JSON input from stdin
      input=$(cat)

      # Extract values from JSON
      cwd=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.workspace.current_dir')
      model=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.model.display_name')
      style=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.output_style.name')

      # Shorten home directory to ~ and get basename
      cwd_display=''${cwd/#$HOME/\~}
      dir_name=$(basename "$cwd_display")

      # Get git branch and status if in a git repo (skip optional locks for safety)
      git_info=""
      git_dirty=""
      if ${pkgs.git}/bin/git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
        git_branch=$(${pkgs.git}/bin/git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
        if [ -n "$git_branch" ]; then
          git_info=" ($git_branch)"
        fi

        # Check if there are uncommitted changes (staged, unstaged, or untracked)
        # Runs outside git_branch conditional to work in detached HEAD state
        if [ -n "$(${pkgs.git}/bin/git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
          git_dirty=" ✗"
        fi
      fi

      # Only show style if it's not "default"
      style_display=""
      if [ "$style" != "default" ]; then
        style_display=" [$style]"
      fi

      # Output the status line in robbyrussell theme format
      # Arrow symbol + directory + git info + dirty indicator | model + style
      printf "➜  %s%s%s | %s%s" "$dir_name" "$git_info" "$git_dirty" "$model" "$style_display"
    '';
    executable = true;
  };
}
# Merge with commands and agents from claude-cookbooks
// claudePlugins.files
# Merge with ai-instructions command symlinks
// mkAiInstructionsCommandSymlinks
