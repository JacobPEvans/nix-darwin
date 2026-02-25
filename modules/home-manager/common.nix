{
  config,
  pkgs,
  lib,
  ai-assistant-instructions,
  marketplaceInputs,
  claude-cookbooks,
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

  # VS Code writable config (activation-based merge, not symlink)
  # Settings are deep-merged into writable files on each rebuild
  vscodeWritableConfig = import ./vscode/writable-config.nix { inherit config lib pkgs; };

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
      ai-assistant-instructions
      marketplaceInputs
      claude-cookbooks
      ;
  };

  # AgentsMD files from Nix store (flake input)
  # Changes require darwin-rebuild, but ensures reproducibility
  # NOTE: .copilot and .gemini directories are NOT symlinked because
  # Nix manages individual files inside them (config.json, commands/*.toml)
  # .gemini/settings.json is managed via activation script (writable at runtime)
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

  # GitHub CLI extensions (aggregated for modularity)
  ghExtensions = import ./ai-cli/gh-extensions {
    inherit
      pkgs
      lib
      ;
    inherit (pkgs) fetchFromGitHub;
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
      // geminiFiles.file
      // codexFiles
      // geminiCommands
      // copilotFiles
      // agentsMdSymlinks
      // gitHooks
      // gitMergeDrivers;

    sessionVariables = {
      EDITOR = "vim";
      # SOPS: age key file for secrets decryption
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    };

    # Activation scripts (run after home files are written)
    activation =
      geminiFiles.activation
      // vscodeWritableConfig.activation
      // {
        # Claude Code Settings Validation (post-rebuild)
        # Validates settings.json against JSON Schema after home files are written
        # Script extracted to scripts/validate-claude-settings.sh for maintainability
        validateClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${./scripts/validate-claude-settings.sh} \
            "${config.home.homeDirectory}/.claude/settings.json" \
            "${userConfig.ai.claudeSchemaUrl}"
        '';

        # open-webui: installed via uv (nixpkgs broken: pgvector→postgresql-test-hook on darwin)
        # Python 3.12 required: open-webui PyPI has Requires-Python <3.13
        installOpenWebui = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if ! ${lib.getExe pkgs.uv} tool list 2>/dev/null | grep -q "^open-webui"; then
            echo "→ Installing open-webui via uv (Python 3.12)..."
            $DRY_RUN_CMD ${lib.getExe pkgs.uv} tool install open-webui --python 3.12
          fi
        '';
      };
  };

  # ==========================================================================
  # Programs Configuration
  # ==========================================================================
  programs = {
    # ==========================================================================
    # VS Code
    # ==========================================================================
    # Settings managed via activation script (writable at runtime).
    # See vscode/writable-config.nix for the deep-merge pattern.
    # profiles.default.userSettings intentionally empty so HM doesn't create
    # a read-only symlink for settings.json.
    vscode = {
      enable = true;
      profiles.default.userSettings = { };
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

        # uv tool installs (e.g. open-webui installed via home-manager activation)
        export PATH="$HOME/.local/bin:$PATH"

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
        source ${./zsh/process-cleanup.zsh}
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
    # GitHub CLI
    # ==========================================================================
    # Declarative management of gh and extensions
    # Extensions are linked to XDG data directory for gh discovery
    gh = {
      enable = true;
      package = pkgs.gh; # GitHub CLI from nixpkgs

      # Extensions installed declaratively
      extensions = [
        # GitHub Agentic Workflows - AI-powered workflows in markdown
        # Source: https://github.com/github/gh-aw
        # Docs: https://github.github.io/gh-aw/
        # Requires: ANTHROPIC_API_KEY or COPILOT_GITHUB_TOKEN (set in env)
        ghExtensions.gh-aw
      ];

      # gh configuration (written to ~/.config/gh/config.yml)
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
      };
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
