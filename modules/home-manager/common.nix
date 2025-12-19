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
  ...
}:

let
  # User-specific configuration (identity, GPG keys, preferences)
  userConfig = import ../../lib/user-config.nix;

  # Git aliases (cross-platform)
  gitAliases = import ./git/aliases.nix;

  # Git hooks (auto-installed via templates)
  gitHooks = import ./git/hooks.nix { inherit config pkgs; };

  # Shell aliases (macOS - see file for sudo requirements)
  shellAliases = import ./zsh/aliases.nix;

  # VS Code settings imports
  vscodeGeneralSettings = import ./vscode/settings.nix { inherit config; };
  vscodeGithubCopilotSettings = import ./vscode/copilot-settings.nix { };

  # npm configuration (home.file entries)
  npmFiles = import ./npm/config.nix { inherit config; };

  # AWS CLI configuration (home.file entries)
  awsFiles = import ./aws/config.nix { inherit config; };

  # Claude Code configuration (extracted to separate file for clarity)
  claudeConfig = import ./ai-cli/claude-config.nix {
    inherit
      config
      pkgs
      lib
      claude-code-plugins
      claude-cookbooks
      claude-plugins-official
      anthropic-skills
      ai-assistant-instructions
      superpowers-marketplace
      ;
  };

  # AgentsMD files from Nix store (flake input)
  # Changes require darwin-rebuild, but ensures reproducibility
  # NOTE: .copilot and .gemini directories are NOT symlinked because
  # Nix manages files inside them (config.json, settings.json)
  agentsMdSymlinks = {
    # Root instruction files accessible from home directory
    # CLAUDE.md and GEMINI.md are pointers to agentsmd/AGENTS.md
    # AGENTS.md contains the actual centralized instructions
    "CLAUDE.md".source = "${ai-assistant-instructions}/CLAUDE.md";
    "GEMINI.md".source = "${ai-assistant-instructions}/GEMINI.md";
    "AGENTS.md".source = "${ai-assistant-instructions}/agentsmd/AGENTS.md";

    # agentsmd - folder containing commands/, rules/, workflows/
    "agentsmd".source = "${ai-assistant-instructions}/agentsmd";
  };
  geminiFiles = import ./ai-cli/gemini.nix { inherit config lib pkgs; };
  copilotFiles = import ./ai-cli/copilot.nix { inherit config lib pkgs; };
in
{
  # ==========================================================================
  # Home Configuration
  # ==========================================================================
  home = {
    stateVersion = userConfig.nix.homeManagerStateVersion;

    # AI CLI Configurations
    # Each AI CLI has its own file in ai-cli/ directory:
    # - claude.nix: Claude Code settings + status line script
    # - gemini.nix: Gemini CLI settings
    # - copilot.nix: GitHub Copilot CLI config
    #
    # Permissions: Now read from JSON in ai-assistant-instructions repo
    # Symlinks: ai-assistant-instructions flake input provides CLAUDE.md, GEMINI.md, AGENTS.md
    # NOTE: claudeFiles removed - now handled by programs.claude module
    file = npmFiles // awsFiles // geminiFiles // copilotFiles // agentsMdSymlinks // gitHooks;

    # Claude Code Settings Validation (post-rebuild)
    # Validates settings.json against JSON Schema after home files are written
    # Script extracted to scripts/validate-claude-settings.sh for maintainability
    activation.validateClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${./scripts/validate-claude-settings.sh} \
        "${config.home.homeDirectory}/.claude/settings.json" \
        "${userConfig.ai.claudeSchemaUrl}"
    '';
  };

  # ==========================================================================
  # Programs Configuration
  # ==========================================================================
  programs = {
    # ==========================================================================
    # VS Code
    # ==========================================================================
    # Settings from vscode-settings.nix and vscode-copilot-settings.nix
    # WARNING: Will overwrite local VS Code settings
    vscode = {
      enable = true;
      profiles.default = {
        # Disable VS Code's built-in update mechanism (Nix manages updates)
        enableUpdateCheck = false; # Sets update.mode = "none"
        enableExtensionUpdateCheck = false; # Sets extensions.autoCheckUpdates = false
        userSettings = {
          "editor.formatOnSave" = true;
        }
        // vscodeGeneralSettings
        // vscodeGithubCopilotSettings;
      };
    };

    # ==========================================================================
    # Shell (zsh)
    # ==========================================================================
    zsh = {
      enable = true;

      # Shell aliases - see shell-aliases.nix for full list and sudo requirements
      inherit shellAliases;

      # Shell enhancements
      autosuggestion.enable = true; # Fish-like autosuggestions
      syntaxHighlighting.enable = true; # Syntax highlighting for commands
      enableCompletion = true; # Tab completion
      history = {
        size = 100000; # Large history for better recall
        save = 100000;
        ignoreDups = true; # Don't save duplicate commands
        ignoreAllDups = true; # Remove older duplicates
        ignoreSpace = true; # Don't save commands starting with space
      };

      # Oh My Zsh - framework for managing zsh configuration
      # Provides themes, plugins, and helper functions
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell"; # Default theme, clean and informative
        plugins = [
          "git" # Git aliases and functions (ga, gc, gp, etc.)
          "docker" # Docker command completion
          "macos" # macOS utilities (ofd, cdf, etc.)
          "z" # Jump to frequently used directories
          "colored-man-pages" # Colorize man pages for readability
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

        # Claude statusline SSH detection (disabled - enhanced statusline unavailable)
        # source ${./zsh/claude-statusline-switch.zsh}

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
    git = {
      enable = true;

      # GPG signing configuration
      # NOTE: Key ID is a public identifier, not the private key (safe to commit)
      signing = {
        key = userConfig.gpg.signingKey;
        signByDefault = true; # Enforced by security policy
      };

      # All git settings (new unified syntax)
      settings = {
        # User identity
        user = {
          name = userConfig.user.fullName;
          inherit (userConfig.user) email;
        };

        # Core settings
        core = {
          inherit (userConfig.git) editor;
          autocrlf = "input"; # LF on commit, unchanged on checkout (Unix-style)
          whitespace = "trailing-space,space-before-tab"; # Highlight whitespace issues
          hooksPath = "${config.home.homeDirectory}/.git-templates/hooks"; # Global hooks for ALL repos
        };

        # Repository initialization
        init = {
          inherit (userConfig.git) defaultBranch;
          # Auto-install hooks on new clones (Layer 1 of pre-commit enforcement)
          templateDir = "${config.home.homeDirectory}/.git-templates";
        };

        # Pull behavior - rebase keeps history cleaner than merge commits
        pull.rebase = true;

        # Push behavior
        push = {
          autoSetupRemote = true; # Auto-track remote branches
          default = "current"; # Push current branch to same-named remote
        };

        # Fetch behavior
        fetch = {
          prune = true; # Auto-remove deleted remote branches
          pruneTags = true; # Auto-remove deleted remote tags
        };

        # Merge & diff improvements
        merge = {
          conflictstyle = "diff3"; # Show original in conflicts (easier resolution)
          ff = "only"; # Only fast-forward merges (use rebase for others)
        };
        diff = {
          algorithm = "histogram"; # Better diff algorithm than default
          colorMoved = "default"; # Highlight moved lines in different color
          mnemonicPrefix = true; # Use i/w/c/o instead of a/b in diffs
        };

        # Rerere - remember merge conflict resolutions
        rerere = {
          enabled = true; # Remember how you resolved conflicts
          autoupdate = true; # Auto-stage rerere resolutions
        };

        # Sign all tags (security policy)
        tag.gpgSign = true;

        # Helpful features
        help.autocorrect = 10; # Auto-correct typos after 1 second
        status.showStash = true; # Show stash count in git status
        log.date = "iso"; # Use ISO date format in logs
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
    direnv = {
      enable = true;
      nix-direnv.enable = true; # Faster, cached nix-shell/flake loading
    };

    # ==========================================================================
    # Home Manager
    # ==========================================================================
    home-manager.enable = true;

    # ==========================================================================
    # Claude Code (Unified Module)
    # ==========================================================================
    # Declarative configuration for Claude Code ecosystem
    # Manages: plugins, commands, agents, skills, hooks, MCP servers
    # Configuration extracted to ai-cli/claude-config.nix for clarity
    claude = claudeConfig;

    # ==========================================================================
    # Agent OS
    # ==========================================================================
    # Spec-driven development system for AI coding agents
    # Commands and agents installed globally to ~/.claude/ (no per-project setup)
    # Config stored in ~/agent-os/config.yml
    agent-os.enable = true;
  };
}
