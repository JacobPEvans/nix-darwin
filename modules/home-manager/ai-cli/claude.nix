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
# Permissions: Generated from unified ai-cli/common/permissions.nix
# - Single source of truth for all AI CLI tools (Claude, Gemini, Copilot)
# - Tool-specific formatting via ai-cli/common/formatters.nix
#
# Validation: CI validates generated settings via validate-claude-settings.yml
#
# Plugins: Configured via claude-plugins.nix
# - Official Anthropic marketplace (claude-code repo)
# - Commands/agents from claude-cookbooks repo
#
# Commands: Symlinked from ai-assistant-instructions repo
# - rok-* community commands (Shape Up workflow)
# - Standard commands (pr, git-refresh, etc.)
#
# Migration Notes:
# - Removed: "commit" - replaced by commit-commands plugin (/commit)
# - Migrated: permissions from JSON to unified Nix definitions (2024-12)

{
  config,
  pkgs,
  lib,
  claude-code-plugins,
  claude-cookbooks,
  claude-plugins-official,
  anthropic-skills,
  ai-assistant-instructions,
  ...
}:

let
  # User configuration
  userConfig = import ../../../lib/user-config.nix;

  # Import unified permissions from wrapper modules
  # These use ai-cli/common/permissions.nix as single source of truth
  claudeAllow = import ../permissions/claude-permissions-allow.nix { inherit config lib; };
  claudeDeny = import ../permissions/claude-permissions-deny.nix { inherit config lib; };
  claudeAsk = import ../permissions/claude-permissions-ask.nix { inherit config lib; };

  # Import plugin configuration (official Anthropic repos)
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

  # NOTE: agentsmd commands are defined in claude-config.nix and processed by
  # components.nix via commands.fromFlakeInputs. No duplicate definition here.

  # Claude Code settings object
  # Generated from lib/claude-settings.nix (shared with CI for cross-platform validation)
  claudeSettings = import ../../../lib/claude-settings.nix {
    homeDir = config.home.homeDirectory;
    schemaUrl = userConfig.ai.claudeSchemaUrl;
    permissions = {
      allow = claudeAllow.allow;
      deny = claudeDeny.deny;
      ask = claudeAsk.ask;
    };
    plugins = claudePlugins.pluginConfig;
  };

  # Generate pretty-printed JSON using a derivation with jq
  # This improves readability for debugging permission issues
  claudeSettingsJson =
    pkgs.runCommand "claude-settings.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
        json = builtins.toJSON claudeSettings;
        passAsFile = [ "json" ];
      }
      ''
        jq '.' "$jsonPath" > $out
      '';

in
{
  # Claude Code settings.json (pretty-printed for debugging)
  ".claude/settings.json".source = claudeSettingsJson;

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
# Merge with commands and agents from plugins
// claudePlugins.files
