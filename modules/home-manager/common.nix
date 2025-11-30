{ config, lib, pkgs, ... }:

let
  # VS Code settings imports
  vscodeGeneralSettings = import ./vscode/settings.nix { inherit config; };
  vscodeGithubCopilotSettings = import ./vscode/copilot-settings.nix { };

  # AI CLI configuration imports (home.file entries)
  claudeFiles = import ./ai-cli/claude.nix { inherit config pkgs; };
  geminiFiles = import ./ai-cli/gemini.nix { inherit config; };
  copilotFiles = import ./ai-cli/copilot.nix { inherit config; };

  # Shell aliases (macOS - see file for sudo requirements)
  shellAliases = import ./zsh/aliases.nix;
in
{
  imports = [
    # Git configuration (programs.git)
    ./git/git-config.nix
  ];

  home.stateVersion = "24.05";

  # ==========================================================================
  # VS Code
  # ==========================================================================
  programs.vscode = {
    enable = true;
    profiles.default.userSettings = {
      "editor.formatOnSave" = true;
    } // vscodeGeneralSettings // vscodeGithubCopilotSettings;
  };

  # ==========================================================================
  # Shell (zsh)
  # ==========================================================================
  programs.zsh = {
    enable = true;
    shellAliases = shellAliases;

    # Shell enhancements
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
    };

    # Oh My Zsh configuration
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";   # Default theme (can be overridden per-shell)
      plugins = [
        "git"
        "docker"
        "macos"
        "z"
        "colored-man-pages"
      ];
    };

    # Source modular shell functions
    # NOTE: Theme override (NIX_SHELL_THEME) is handled at the start with mkBefore
    initContent = lib.mkMerge [
      # FIRST: Check for shell-specific theme override BEFORE oh-my-zsh loads
      (lib.mkBefore ''
        # Allow dev shells to override the theme via NIX_SHELL_THEME
        if [[ -n "$NIX_SHELL_THEME" ]]; then
          ZSH_THEME="$NIX_SHELL_THEME"
        fi
      '')
      # AFTER: Source modular shell functions
      ''
        # GPG: Required for pinentry to prompt for passphrase in terminal
        export GPG_TTY=$(tty)

        source ${./zsh/git-functions.zsh}
        source ${./zsh/docker-functions.zsh}
        source ${./zsh/macos-setup.zsh}
        source ${./zsh/session-logging.zsh}
      ''
    ];
  };

  # ==========================================================================
  # Direnv (per-project environments)
  # ==========================================================================
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # ==========================================================================
  # Home Manager
  # ==========================================================================
  programs.home-manager.enable = true;

  # ==========================================================================
  # AI CLI Configurations
  # ==========================================================================
  # Each AI CLI has its own file in ai-cli/ directory
  home.file = claudeFiles // geminiFiles // copilotFiles;
}
