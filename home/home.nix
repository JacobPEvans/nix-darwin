{ config, pkgs, ... }:

let
  # Import Claude Code permission definitions
  claudePerms = import ./claude-permissions.nix { };
  claudeAsks = import ./claude-permissions-ask.nix { };
in
{
  home.stateVersion = "24.05";

  # VS Code configuration
  ### WILL OVERWRITE ANYTHING LOCAL ###
  programs.vscode = {
    enable = true;
    profiles.default.userSettings = {
      "editor.formatOnSave" = true;
    };
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

      # Quick docker aliases
      dps = "docker ps -a";
      dcu = "docker compose up -d";
      dcd = "docker compose down";

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
  # - Run: darwin-rebuild switch --flake ~/.config/nix#default
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
  };

  # NOTE: settings.local.json is intentionally NOT managed by Nix
  # This allows Claude to write interactive approvals there
  # If you want FULL Nix control, add it here and it will become read-only
}
