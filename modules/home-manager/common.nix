{ config, pkgs, lib, claude-code-plugins, claude-cookbooks, ai-assistant-instructions, ... }:

let
  # User-specific configuration (identity, GPG keys, preferences)
  userConfig = import ../../lib/user-config.nix;

  # Git aliases (cross-platform)
  gitAliases = import ./git/aliases.nix;

  # Shell aliases (macOS - see file for sudo requirements)
  shellAliases = import ./zsh/aliases.nix;

  # VS Code settings imports
  vscodeGeneralSettings = import ./vscode/settings.nix { inherit config; };
  vscodeGithubCopilotSettings = import ./vscode/copilot-settings.nix { };

  # npm configuration (home.file entries)
  npmFiles = import ./npm/config.nix { inherit config; };

  # AWS CLI configuration (home.file entries)
  awsFiles = import ./aws/config.nix { inherit config; };

  # AI CLI configuration imports (home.file entries)
  # Claude plugins require external repo inputs from flake.nix
  claudeFiles = import ./ai-cli/claude.nix {
    inherit config pkgs lib claude-code-plugins claude-cookbooks ai-assistant-instructions;
  };

  # Path to ai-assistant-instructions git repo for symlinks
  # Using mkOutOfStoreSymlink for live updates without darwin-rebuild
  # Single source of truth in lib/user-config.nix (DRY - also used by claude.nix)
  # See user-config.nix for clone instructions if the repo is missing
  aiInstructionsRepo = userConfig.ai.instructionsRepo;

  # Home directory symlinks to ai-assistant-instructions repo
  # These provide global access to AI instruction files
  # NOTE: .copilot and .gemini directories are NOT symlinked because
  # Nix manages files inside them (config.json, settings.json)
  aiInstructionsSymlinks = {
    # Root instruction files accessible from home directory
    "CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${aiInstructionsRepo}/CLAUDE.md";
    "GEMINI.md".source = config.lib.file.mkOutOfStoreSymlink "${aiInstructionsRepo}/GEMINI.md";

    # AI instruction directories (only those without Nix-managed files inside)
    ".ai-instructions".source = config.lib.file.mkOutOfStoreSymlink "${aiInstructionsRepo}/.ai-instructions";
  };
  geminiFiles = import ./ai-cli/gemini.nix { inherit config; };
  copilotFiles = import ./ai-cli/copilot.nix { inherit config; };
in
{
  home.stateVersion = "24.05";

  # ==========================================================================
  # VS Code
  # ==========================================================================
  # Settings from vscode-settings.nix and vscode-copilot-settings.nix
  # WARNING: Will overwrite local VS Code settings
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

    # Shell aliases - see shell-aliases.nix for full list and sudo requirements
    shellAliases = shellAliases;

    # Shell enhancements
    autosuggestion.enable = true;     # Fish-like autosuggestions
    syntaxHighlighting.enable = true; # Syntax highlighting for commands
    enableCompletion = true;          # Tab completion
    history = {
      size = 100000;                  # Large history for better recall
      save = 100000;
      ignoreDups = true;              # Don't save duplicate commands
      ignoreAllDups = true;           # Remove older duplicates
      ignoreSpace = true;             # Don't save commands starting with space
    };

    # Oh My Zsh - framework for managing zsh configuration
    # Provides themes, plugins, and helper functions
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";  # Default theme, clean and informative
      plugins = [
        "git"           # Git aliases and functions (ga, gc, gp, etc.)
        "docker"        # Docker command completion
        "macos"         # macOS utilities (ofd, cdf, etc.)
        "z"             # Jump to frequently used directories
        "colored-man-pages"  # Colorize man pages for readability
      ];
    };

    # Source modular shell functions
    # NOTE: session-logging.zsh MUST be last (takes over terminal)
    initContent = ''
      # GPG: Required for pinentry to prompt for passphrase in terminal
      export GPG_TTY=$(tty)

      # npm global packages (managed via ~/.npmrc prefix)
      # Packages installed with: npm install -g <package>
      # are placed in ~/.npm-packages and available in PATH
      export PATH="$HOME/.npm-packages/bin:$PATH"
      export NODE_PATH="$HOME/.npm-packages/lib/node_modules"

      source ${./zsh/git-functions.zsh}
      source ${./zsh/docker-functions.zsh}
      source ${./zsh/macos-setup.zsh}
      source ${./zsh/session-logging.zsh}
    '';
  };

  # ==========================================================================
  # Git
  # ==========================================================================
  # Fully Nix-managed git config (~/.config/git/config)
  # Security policy: All commits and tags must be GPG signed
  # User values from lib/user-config.nix
  programs.git = {
    enable = true;

    # GPG signing configuration
    # NOTE: Key ID is a public identifier, not the private key (safe to commit)
    signing = {
      key = userConfig.gpg.signingKey;
      signByDefault = true;  # Enforced by security policy
    };

    # All git settings (new unified syntax)
    settings = {
      # User identity
      user = {
        name = userConfig.user.fullName;
        email = userConfig.user.email;
      };

      # Core settings
      core = {
        editor = userConfig.git.editor;
        autocrlf = "input";           # LF on commit, unchanged on checkout (Unix-style)
        whitespace = "trailing-space,space-before-tab";  # Highlight whitespace issues
      };

      # Repository initialization
      init.defaultBranch = userConfig.git.defaultBranch;

      # Pull behavior - rebase keeps history cleaner than merge commits
      pull.rebase = true;

      # Push behavior
      push = {
        autoSetupRemote = true;       # Auto-track remote branches
        default = "current";          # Push current branch to same-named remote
      };

      # Fetch behavior
      fetch = {
        prune = true;                 # Auto-remove deleted remote branches
        pruneTags = true;             # Auto-remove deleted remote tags
      };

      # Merge & diff improvements
      merge = {
        conflictstyle = "diff3";      # Show original in conflicts (easier resolution)
        ff = "only";                  # Only fast-forward merges (use rebase for others)
      };
      diff = {
        algorithm = "histogram";      # Better diff algorithm than default
        colorMoved = "default";       # Highlight moved lines in different color
        mnemonicPrefix = true;        # Use i/w/c/o instead of a/b in diffs
      };

      # Rerere - remember merge conflict resolutions
      rerere = {
        enabled = true;               # Remember how you resolved conflicts
        autoupdate = true;            # Auto-stage rerere resolutions
      };

      # Sign all tags (security policy)
      tag.gpgSign = true;

      # Helpful features
      help.autocorrect = 10;          # Auto-correct typos after 1 second
      status.showStash = true;        # Show stash count in git status
      log.date = "iso";               # Use ISO date format in logs
      branch.sort = "-committerdate"; # Sort branches by recent commits

      # Git aliases - see git-aliases.nix for full list
      alias = gitAliases;
    };
  };

  # ==========================================================================
  # Direnv (per-project environments)
  # ==========================================================================
  # Automatically loads .envrc files when entering directories
  # Usage: Create .envrc with "use flake" or "use nix" and run "direnv allow"
  # See shells/ directory for example flake.nix files
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;  # Faster, cached nix-shell/flake loading
  };

  # ==========================================================================
  # Home Manager
  # ==========================================================================
  programs.home-manager.enable = true;

  # ==========================================================================
  # AI CLI Configurations
  # ==========================================================================
  # Each AI CLI has its own file in ai-cli/ directory:
  # - claude.nix: Claude Code settings + status line script
  # - gemini.nix: Gemini CLI settings
  # - copilot.nix: GitHub Copilot CLI config
  #
  # Permissions: Now read from JSON in ai-assistant-instructions repo
  # Symlinks: ai-instructions provides CLAUDE.md, GEMINI.md, .ai-instructions/, etc.
  home.file = npmFiles // awsFiles // claudeFiles // geminiFiles // copilotFiles // aiInstructionsSymlinks;

  # ==========================================================================
  # Agent OS
  # ==========================================================================
  # Spec-driven development system for AI coding agents
  # Commands and agents installed globally to ~/.claude/ (no per-project setup)
  # Config stored in ~/agent-os/config.yml
  programs.agent-os.enable = true;
}
