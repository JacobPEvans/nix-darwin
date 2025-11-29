# Claude Code Configuration
#
# Returns home.file entries for Claude Code settings and status line.
# Imported by home.nix for clean separation of AI CLI configs.
#
# Strategy: Layered configuration approach
# 1. Nix manages settings.json (this file) - baseline approved commands
# 2. settings.local.json remains WRITABLE - for interactive "accept indefinitely"
# 3. Claude merges both: local overrides base

{ config, pkgs, ... }:

let
  claudePerms = import ../permissions/claude-permissions.nix { };
  claudeAsks = import ../permissions/claude-permissions-ask.nix { };
in
{
  # Claude Code settings.json
  ".claude/settings.json".text = builtins.toJSON {
    # Enable extended thinking mode
    alwaysThinkingEnabled = true;

    # Auto-approved commands (managed by Nix)
    # See home/claude-permissions.nix for full categorized list
    # User-prompted commands in home/claude-permissions-ask.nix
    permissions = {
      allow = claudePerms.allowList;
      deny = claudePerms.denyList;
      ask = claudeAsks.askList;
    };

    # Status line configuration
    statusLine = {
      type = "command";
      command = "${config.home.homeDirectory}/.claude/statusline-command.sh";
    };
  };

  # Claude Code status line script
  # Displays: current directory, git branch, model name, output style
  ".claude/statusline-command.sh" = {
    text = ''
      #!/bin/bash

      # Read JSON input from stdin
      input=$(cat)

      # Extract values from JSON
      cwd=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.workspace.current_dir')
      model=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.model.display_name')
      style=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.output_style.name')

      # Shorten home directory to ~
      cwd_display=''${cwd/#$HOME/\~}

      # Get git branch if in a git repo (skip optional locks for safety)
      git_branch=""
      if ${pkgs.git}/bin/git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
        git_branch=$(${pkgs.git}/bin/git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
        if [ -n "$git_branch" ]; then
          git_branch=" on $git_branch"
        fi
      fi

      # Only show style if it's not "default"
      style_display=""
      if [ "$style" != "default" ]; then
        style_display=" [$style]"
      fi

      # Output the status line
      printf "%s%s | %s%s" "$cwd_display" "$git_branch" "$model" "$style_display"
    '';
    executable = true;
  };
}
