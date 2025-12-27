{ pkgs, lib, ... }:

let
  userConfig = import ../../lib/user-config.nix;

  # Universal packages (pre-commit, linters) shared across all systems
  commonPackages = import ../common/packages.nix { inherit pkgs; };
in
{
  imports = [
    ./apps
    ./dock
    ./file-extensions.nix
    ./finder.nix
    ./keyboard.nix
    ./security.nix
    ./terminal.nix
    ./trackpad.nix
    ./system-ui.nix
  ];

  # ==========================================================================
  # Nixpkgs Configuration
  # ==========================================================================
  nixpkgs.config.allowUnfree = true;

  # Overlays for package overrides (e.g., updating outdated packages)
  # See overlays/ directory for individual overlay files
  nixpkgs.overlays = [
    (import ../../overlays/python-packages.nix)
  ];

  # ==========================================================================
  # User Configuration
  # ==========================================================================
  users.users.${userConfig.user.name} = {
    inherit (userConfig.user) name;
    home = userConfig.user.homeDir;
  };

  # System packages from nixpkgs
  # All packages should come from nixpkgs - homebrew is fallback only
  environment.systemPackages =
    commonPackages
    ++ (with pkgs; [
      # ========================================================================
      # Core CLI tools
      # ========================================================================
      git
      gnupg
      vim

      # ========================================================================
      # Modern CLI tools (popular alternatives, also useful for AI CLI agents)
      # These enhance productivity for both humans and AI assistants
      # ========================================================================
      bat # Better cat with syntax highlighting
      delta # Better git diff viewer with syntax highlighting
      eza # Modern ls replacement with git integration
      fd # Faster, user-friendly find alternative
      fzf # Fuzzy finder for interactive selection
      gnugrep # GNU grep with zgrep for compressed files
      gnutar # GNU tar as 'gtar' (Mac-safe tar without ._* files)
      htop # Interactive process viewer (better top)
      jq # JSON parsing for config files and API responses
      ncdu # NCurses disk usage analyzer
      ngrep # Network packet grep (useful for debugging)
      procps # Process utilities including pgrep, pkill
      ripgrep # Fast grep alternative (rg) - essential for AI agents
      tldr # Simplified, community-driven man pages
      tree # Directory tree visualization
      yq # YAML parsing (like jq but for YAML/XML/TOML)

      # ========================================================================
      # Development tools
      # ========================================================================
      claude-code # Anthropic's agentic coding CLI
      claude-monitor # Real-time Claude Code usage monitor
      gemini-cli # Google's Gemini CLI
      opencode # Provider-agnostic AI coding agent
      gh # GitHub CLI

      mas # Mac App Store CLI (search: mas search <app>, install: mas install <id>)
      nodejs # Node.js LTS (nixpkgs default tracks current LTS)
      ollama # LLM runtime (nixpkgs 0.13.2, replaces manual 0.12.10 install)
      # Models stored on dedicated APFS volume /Volumes/Ollama/models
      # See hosts/macbook-m4/home.nix for symlink configuration

      # ========================================================================
      # GUI applications
      # ========================================================================
      bitwarden-desktop # Password manager desktop app
      # NOTE: ghostty-bin moved to home.packages for TCC permission persistence
      # See hosts/macbook-m4/home.nix for details
      obsidian # Knowledge base / note-taking (Markdown)
      # NOTE: OrbStack managed via programs.orbstack module for system-level
      # installation. See modules/darwin/apps/orbstack.nix and
      # hosts/macbook-m4/default.nix for configuration.
      # NOTE: Zoom moved to home.packages for better handling of TCC
      # (camera/mic/screen) permissions via stable trampolines (wrapper apps with
      # stable paths; see hosts/macbook-m4/home.nix). Apps that frequently need
      # these permissions (e.g., Zoom for video calls) benefit most.
      raycast # Productivity launcher (replaces Spotlight)
      swiftbar # Menu bar customization (auto-claude status)
      vscode # Visual Studio Code editor
    ]);

  # Homebrew as FALLBACK ONLY for packages not in nixpkgs or severely outdated
  # Prefer nixpkgs for everything - only use homebrew when absolutely necessary
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false; # Don't download 45MB index on every rebuild (fast)
      cleanup = "none"; # Don't remove manually installed packages
      upgrade = true; # Upgrade packages based on cached index
      # To get new versions: run `brew update` then `darwin-rebuild switch`
    };
    taps = [
      # "homebrew/cask"   # Example: additional taps
    ];
    brews = [
      # CLI tools (only if not available in nixpkgs)
      "ccusage" # Claude Code usage analyzer (not in nixpkgs)
    ];
    casks = [
      # GUI applications (only if not available in nixpkgs)
    ];

    # Mac App Store apps (requires signed into App Store)
    # Find app IDs: mas search <name> or https://github.com/mas-cli/mas
    # Format: "App Name" = app_id;
    masApps = {
      # "Xcode" = 497799835;
      # "1Password" = 1333542190;
    };
  };

  # ==========================================================================
  # Programs Configuration
  # ==========================================================================
  programs = {
    zsh.enable = true;
    raycast.enable = true; # Declarative Raycast preferences
    terminal.enable = true; # Terminal.app window size (180x80 for Basic profile)
  };

  # ==========================================================================
  # Nix Configuration (Determinate Nix compatibility)
  # ==========================================================================
  # Disable nix-darwin's Nix management - Determinate Nix manages daemon and nix itself
  # Workaround: home-manager's darwin module accesses nix.package even when enable=false
  # Using mkForce bypasses the throw in nix-darwin's managedDefault
  # See: https://github.com/nix-community/home-manager/issues/4026
  nix = {
    enable = false;
    package = lib.mkForce pkgs.nix;
    # Note: nix.gc cannot be configured when nix.enable = false
    # Determinate Nix manages garbage collection via its own mechanisms
    # For manual GC, use: nix-collect-garbage --delete-older-than 30d
  };

  # Add Nix settings via conf.d snippet, as nix.settings is ignored when nix.enable = false.
  environment.etc."nix/conf.d/gc.conf".text = "auto-optimise-store = true";

  # Disable documentation to suppress builtins.toFile warnings
  documentation.enable = false;

  # ==========================================================================
  # System Configuration (Activation Scripts & State Version)
  # ==========================================================================
  # Activation scripts run during darwin-rebuild to verify system state and prevent
  # silent activation failures that leave /run/current-system pointing to stale generations
  system = {
    # Required for nix-darwin with Determinate Nix
    primaryUser = userConfig.user.name;

    activationScripts = {
      preActivation.text = ''
        # DEBUG: Enable command tracing for activation debugging
        set -x

        echo "[DEBUG] ========================================" >&2
        echo "[DEBUG] preActivation: Starting" >&2
        echo "[DEBUG] User: $(whoami)" >&2
        echo "[DEBUG] UID: $(id -u)" >&2
        echo "[DEBUG] systemConfig: $systemConfig" >&2
        echo "[DEBUG] Current /run/current-system: $(readlink -f /run/current-system 2>&1 || echo 'FAILED TO READ')" >&2
        echo "[DEBUG] ========================================" >&2

        # Trap signals to prevent leaving system in bad state if interrupted
        cleanup() {
          echo "❌ Activation interrupted - system may be in an inconsistent state" >&2
          echo "Run: sudo darwin-rebuild activate" >&2
          exit 1
        }
        trap cleanup INT TERM

        # Verify /run is writable (required to update /run/current-system symlink)
        if [ ! -w /run ]; then
          echo "❌ ERROR: Cannot write to /run directory" >&2
          echo "Check permissions and ensure running as root" >&2
          exit 1
        fi

        echo "[DEBUG] preActivation: /run is writable" >&2
        echo "[DEBUG] preActivation: Completed" >&2
      '';

      postActivation.text = ''
        # DEBUG: Log that we reached postActivation
        echo "[DEBUG] postActivation: Starting verification" >&2
        echo "[DEBUG] systemConfig=$systemConfig" >&2

        # Verify /run/current-system points to this generation
        # This catches silent activation failures where the build succeeds but
        # the symlink update doesn't happen (permissions, interrupts, etc.)
        # NOTE: Does NOT exit on failure (would kill activation). Just warns.
        EXPECTED="$systemConfig"
        ACTUAL="$(readlink -f /run/current-system)"

        echo "[DEBUG] EXPECTED=$EXPECTED" >&2
        echo "[DEBUG] ACTUAL=$ACTUAL" >&2

        # Using POSIX-compliant [ ] test for portability
        if [ "$EXPECTED" != "$ACTUAL" ]; then
          echo "⚠️  WARNING: Activation verification detected a mismatch" >&2
          echo "Expected: $EXPECTED" >&2
          echo "Actual:   $ACTUAL" >&2
          echo "" >&2
          echo "This may indicate the /run/current-system symlink update is pending." >&2
          echo "If this warning persists after activation completes, run:" >&2
          echo "  sudo /nix/var/nix/profiles/system/activate" >&2
          echo "" >&2
          # CRITICAL: Do NOT exit here - it kills the entire activation!
          # Let activation complete and allow darwin-rebuild to update the symlink
        else
          echo "✅ Activation verified: /run/current-system updated successfully" >&2
        fi

        echo "[DEBUG] postActivation: Completed" >&2
      '';

      # CRITICAL DEBUG: This runs as close to the end as possible
      # According to research, the symlink update is the LAST command in the activate script
      # If this runs, we know we got past all other activation scripts
      finalDebug.text = ''
        echo "[DEBUG] ========================================" >&2
        echo "[DEBUG] finalDebug: This is the LAST activation script before symlink update" >&2
        echo "[DEBUG] systemConfig=$systemConfig" >&2
        echo "[DEBUG] Current /run/current-system: $(readlink -f /run/current-system)" >&2
        echo "[DEBUG] Expected after update: $systemConfig" >&2
        echo "[DEBUG] Current directory: $(pwd)" >&2
        echo "[DEBUG] Script running as: $(whoami) (UID: $(id -u))" >&2
        echo "[DEBUG] /run permissions: $(ls -ld /run)" >&2
        echo "[DEBUG] /run/current-system permissions: $(ls -l /run/current-system)" >&2
        echo "[DEBUG] Testing if we can create symlink..." >&2

        # Test symlink creation ability
        TEST_LINK="/tmp/test-symlink-$$"
        if ln -sfn "$systemConfig" "$TEST_LINK" 2>&1; then
          echo "[DEBUG] ✅ Can create symlinks (test: $TEST_LINK -> $systemConfig)" >&2
          rm -f "$TEST_LINK"
        else
          echo "[DEBUG] ❌ CANNOT create symlinks! Error: $?" >&2
        fi

        echo "[DEBUG] About to exit finalDebug - next is the ln -sfn for /run/current-system" >&2
        echo "[DEBUG] ========================================" >&2
      '';
    };

    # macOS system version (required for nix-darwin)
    stateVersion = 5;
  };
}
