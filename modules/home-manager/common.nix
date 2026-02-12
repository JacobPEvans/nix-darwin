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
  jacobpevans-cc-plugins,
  claude-code-workflows,
  claude-skills,
  ...
}:

let
  # User-specific configuration (identity, GPG keys, preferences)
  userConfig = import ../../lib/user-config.nix;

  # Git aliases (cross-platform)
  gitAliases = import ./git/aliases.nix;

  # Git hooks (auto-installed via templates)
  gitHooks = import ./git/hooks.nix { inherit config pkgs; };

  # Git configuration (extracted to reduce file size)
  gitConfig = import ./git/config.nix { inherit config userConfig gitAliases; };

  # Git merge driver for flake.lock (auto-regenerate on conflict)
  gitMergeDrivers = {
    ".local/bin/git-merge-flakelock" = {
      source = ./git/merge-flakelock.sh;
      executable = true;
    };
  };

  # Shell aliases (macOS - see file for sudo requirements)
  shellAliases = import ./zsh/aliases.nix;

  # VS Code settings imports
  vscodeGeneralSettings = import ./vscode/settings.nix { inherit config; };
  vscodeGithubCopilotSettings = import ./vscode/copilot-settings.nix { };

  # npm configuration (home.file entries)
  npmFiles = import ./npm/config.nix { inherit config; };

  # AWS CLI configuration (home.file entries)
  awsFiles = import ./aws/config.nix { inherit config; };

  # Linter configurations (markdownlint, etc.)
  linterFiles = import ./linters/markdownlint.nix { inherit config; };

  # Claude Code configuration (extracted to separate file for clarity)
  claudeConfig = import ./ai-cli/claude-config.nix {
    inherit
      config
      lib
      claude-code-plugins
      claude-cookbooks
      claude-plugins-official
      anthropic-skills
      ai-assistant-instructions
      superpowers-marketplace
      jacobpevans-cc-plugins
      claude-code-workflows
      claude-skills
      ;
  };

  # AgentsMD files from Nix store (flake input)
  # Changes require darwin-rebuild, but ensures reproducibility
  # NOTE: .copilot and .gemini directories are NOT symlinked because
  # Nix manages files inside them (config.json, settings.json)
  # Uses force = true to overwrite any existing files (git provides version control)
  agentsMdSymlinks = {
    # Root instruction files accessible from home directory
    # CLAUDE.md and GEMINI.md are pointers to agentsmd/AGENTS.md
    # AGENTS.md contains the actual centralized instructions
    "CLAUDE.md" = {
      source = "${ai-assistant-instructions}/CLAUDE.md";
      force = true;
    };
    "GEMINI.md" = {
      source = "${ai-assistant-instructions}/GEMINI.md";
      force = true;
    };
    "AGENTS.md" = {
      source = "${ai-assistant-instructions}/AGENTS.md";
      force = true;
    };

    # agentsmd - folder containing commands/, rules/, workflows/
    "agentsmd" = {
      source = "${ai-assistant-instructions}/agentsmd";
      force = true;
    };
  };
  geminiFiles = import ./ai-cli/gemini.nix {
    inherit
      config
      lib
      pkgs
      ai-assistant-instructions
      ;
  };
  codexFiles = import ./ai-cli/codex.nix { inherit pkgs; };
  geminiCommands = import ./ai-cli/gemini-commands.nix {
    inherit lib ai-assistant-instructions;
  };
  copilotFiles = import ./ai-cli/copilot.nix {
    inherit
      config
      lib
      pkgs
      ai-assistant-instructions
      ;
  };
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
    file =
      npmFiles
      // awsFiles
      // linterFiles
      // geminiFiles
      // codexFiles
      // geminiCommands
      // copilotFiles
      // agentsMdSymlinks
      // gitHooks
      // gitMergeDrivers;

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

        # MCP Server API keys (from macOS Keychain)
        # GitHub - for github@claude-plugins-official MCP server
        export GITHUB_PERSONAL_ACCESS_TOKEN=''${GITHUB_PERSONAL_ACCESS_TOKEN:-"$(security find-generic-password \
          -s "github-pat" -a "${userConfig.user.name}" -w 2>/dev/null || echo "")"}
        # Context7 - for context7@claude-plugins-official MCP server
        export CONTEXT7_API_KEY=''${CONTEXT7_API_KEY:-"$(security find-generic-password \
          -s "CONTEXT7_API_KEY" -a "${userConfig.user.name}" -w 2>/dev/null || echo "")"}


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
    # Configuration extracted to git/config.nix to reduce file size
    # Security policy: All commits and tags must be GPG signed
    git = gitConfig;

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
    # Claude Statusline
    # ==========================================================================
    # Powerline-style statusline for Claude Code terminal
    # Uses @owloops/claude-powerline via bunx at runtime (no build hashes)
    # Config: Rose Pine theme, capsule style, 3-line layout
    claudeStatusline.enable = true;

  };
}
