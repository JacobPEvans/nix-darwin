{ config, pkgs, ... }:

let
  # Import Claude Code permission definitions
  claudePerms = import ./claude-permissions.nix { };
  claudeAsks = import ./claude-permissions-ask.nix { };

  # Import Gemini CLI permission definitions
  geminiPerms = import ./gemini-permissions.nix { };

  # Import Copilot CLI configuration
  copilotConfig = import ./copilot-permissions.nix { inherit config; };

  # Import VS Code Copilot settings
  vscodeGithubCopilotSettings = import ./vscode-copilot-settings.nix { };
in
{
  home.stateVersion = "24.05";

  # VS Code configuration
  ### WILL OVERWRITE ANYTHING LOCAL ###
  programs.vscode = {
    enable = true;
    profiles.default.userSettings = {
      "editor.formatOnSave" = true;
    } // vscodeGithubCopilotSettings; # Merge GitHub Copilot settings
  };

  # Shell configuration
  programs.zsh = {
    enable = true;

    ## Environment variables
    #sessionVariables = {
    #  PATH = "/opt/homebrew/opt/python@3.12/bin:$PATH";
    #};

    # Aliases from your .zshrc
    shellAliases = {
      # Everyday shell aliases
      ll = "ls -ahlFG -D '%Y-%m-%d %H:%M:%S'";
      llt = "ls -ahltFG -D '%Y-%m-%d %H:%M:%S'";
      lls = "ls -ahlsFG -D '%Y-%m-%d %H:%M:%S'";

      # Nix-related aliases
      d-r = "sudo darwin-rebuild switch --flake ~/.config/nix#default";

      # Python alias - use macOS built-in python3
      python = "python3";

      # Tar alias for Mac
      tgz = "tar --disable-copyfile --exclude='.DS_Store' -czf";
    };

    # Init content - source modular shell configuration files
    # Files are sourced in order; session-logging.zsh MUST be last
    initContent = ''
      # Load function libraries
      source ${./zsh/git-functions.zsh}
      source ${./zsh/docker-functions.zsh}

      # macOS-specific setup and cleanup
      source ${./zsh/macos-setup.zsh}

      # Session logging MUST be last (takes over terminal)
      source ${./zsh/session-logging.zsh}
    '';
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # ====================================================================
  # Claude Code Configuration
  # ====================================================================
  # Strategy: Layered configuration approach
  #
  # 1. Nix manages settings.json (this file) - baseline approved commands
  # 2. settings.local.json remains WRITABLE - for interactive "accept indefinitely"
  # 3. Claude merges both: local overrides base
  #
  # Benefits:
  # - Reproducible baseline (version controlled)
  # - Still allows ad-hoc approvals via UI
  # - Easy to sync across machines
  #
  # To add more approved commands:
  # - Edit home/claude-permissions.nix
  # - Run: sudo darwin-rebuild switch --flake ~/.config/nix#default
  # ====================================================================

  home.file.".claude/settings.json".text = builtins.toJSON {
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

  # NOTE: settings.local.json is intentionally NOT managed by Nix
  # This allows Claude to write interactive approvals there
  # If you want FULL Nix control, add it here and it will become read-only

  # ====================================================================
  # Claude Code Status Line
  # ====================================================================
  # Custom status line script that displays:
  # - Current directory (with ~ for home)
  # - Git branch (if in a git repo)
  # - Model display name
  # - Output style (if not default)
  # ====================================================================

  home.file.".claude/statusline-command.sh" = {
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

  # ====================================================================
  # Gemini CLI Configuration
  # ====================================================================
  # Strategy: Managed configuration for Google Gemini Code Assist CLI
  #
  # Configuration format:
  # - coreTools: List of allowed built-in tools and shell commands
  # - excludeTools: List of permanently blocked commands
  #
  # See home/gemini-permissions.nix for categorized command lists
  # Mirrors Claude Code permission structure for consistency
  # ====================================================================

  home.file.".gemini/settings.json".text = builtins.toJSON {
    # Allowed tools (safe, read-focused operations)
    coreTools = geminiPerms.coreTools;

    # Blocked tools (catastrophic operations)
    excludeTools = geminiPerms.excludeTools;

    # Additional Gemini CLI settings can be added here
    # See: https://google-gemini.github.io/gemini-cli/docs/get-started/configuration.html
  };

  # ====================================================================
  # GitHub Copilot CLI Configuration
  # ====================================================================
  # Strategy: Directory trust model with runtime permission flags
  #
  # Configuration format:
  # - config.json: Contains trusted_folders array
  # - CLI flags: --allow-tool and --deny-tool (runtime only)
  #
  # Note: Unlike Claude/Gemini, Copilot's permission system is primarily
  # CLI-flag based. The config file only manages directory trust.
  #
  # See home/copilot-permissions.nix for:
  # - Trusted folder list
  # - Recommended CLI flag patterns
  # - Implementation examples
  # ====================================================================

  home.file.".copilot/config.json".text = builtins.toJSON {
    # Trusted directories where Copilot can operate without confirmation
    trusted_folders = copilotConfig.trusted_folders;

    # Additional Copilot CLI settings can be added here
    # Note: Tool-level permissions require CLI flags, not config settings
  };
}
