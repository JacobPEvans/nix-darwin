{
  pkgs,
  lib,
  unstablePkgs,
  ...
}:

let
  userConfig = import ../../lib/user-config.nix;

  # Universal packages (pre-commit, linters) shared across all systems
  commonPackages = import ../common/packages.nix { inherit pkgs; };
in
{
  imports = [
    ./apps
    ./dock
    ./energy.nix
    ./file-extensions.nix
    ./finder.nix
    ./homebrew.nix
    ./keyboard.nix
    ./launchd-bootstrap.nix
    ./logging.nix # Syslog forwarding to remote server
    ./boot-activation.nix # Creates /run/current-system at boot
    ./auto-recovery.nix
    ./security.nix
    ./trackpad.nix
    ./system-ui.nix
    ./activation-error-tracking.nix
  ];

  # --- Nixpkgs Configuration ---
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import ../../overlays/python-packages.nix)
    (import ../../overlays/macos-apps.nix)
    # GUI apps from nixpkgs-unstable for faster version updates
    # Stable branches (25.11) only get security fixes, not version bumps
    # This overlay ensures GUI apps and fast-moving tools stay current with upstream releases
    (_final: _prev: {
      inherit (unstablePkgs)
        antigravity
        bitwarden-desktop
        chatgpt
        code-cursor
        ghostty-bin
        obsidian
        ollama
        postman
        rapidapi
        raycast
        swiftbar
        ;
    })
  ];

  # --- User Configuration ---
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

      # --- Development tools ---
    ])
    ++ (with pkgs; [
      mas # Mac App Store CLI
      nodejs # Node.js LTS (nixpkgs default tracks current LTS)
      ollama # LLM runtime (models on /Volumes/Ollama/models)

      # --- GUI applications ---
      bitwarden-desktop # Password manager desktop app
      # NOTE: ghostty-bin moved to home.packages for TCC permission persistence
      # See hosts/macbook-m4/home.nix for details
      obsidian # Knowledge base / note-taking (Markdown)
      # NOTE: OrbStack managed via programs.orbstack module for system-level
      # installation. See modules/darwin/apps/orbstack.nix and
      # hosts/macbook-m4/default.nix for configuration.
      # NOTE: Zoom was in home.packages but is now DISABLED.
      # See hosts/macbook-m4/home.nix for TCC-sensitive app configuration.
      raycast # Productivity launcher (replaces Spotlight)
      swiftbar # Menu bar customization (auto-claude status)
      # NOTE: VS Code managed via programs.vscode in home-manager (with copyApps)
    ]);

  # --- Homebrew Configuration ---
  # See ./homebrew.nix for casks, brews, and masApps

  # --- Programs Configuration ---
  programs = {
    zsh.enable = true;
    raycast.enable = true;
  };

  # --- Nix Configuration (Determinate Nix compatibility) ---
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

  documentation.enable = false;

  # --- System Configuration (Activation Scripts) ---
  # Activation scripts verify system state and prevent silent failures
  # ⚠️ CRITICAL: See docs/ACTIVATION-SCRIPTS-RULES.md for mandatory rules
  system = {
    # Required for nix-darwin with Determinate Nix
    primaryUser = userConfig.user.name;

    activationScripts = {
      preActivation.text = ''
        # CRITICAL: Disable 'set -e' to prevent non-zero exit codes from aborting
        # the entire activation script. See docs/ACTIVATION-SCRIPTS-RULES.md Rule 1.
        #
        # Summary: nix-darwin's activate script uses 'set -e'. Commands like
        # 'launchctl asuser' return non-zero exit codes even on success. Without
        # 'set +e', the script aborts BEFORE updating /run/current-system, causing
        # a silent partial deployment (home-manager updates but system stays old).
        set +e

        echo "→ Starting activation (user: $(whoami), uid: $(id -u))"

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
      '';

      # Runs after all activation scripts, just before symlink update
      # NOTE: Can't verify /run/current-system here - it updates after this script
      postActivation.text = ''
        # Get timestamps using ls -lT (macOS format: Mon DD HH:MM:SS YYYY)
        # shellcheck disable=SC2012
        TIMESTAMPS=$(ls -ldT "$systemConfig" 2>/dev/null | awk '{print $6, $7, $8, $9}')

        echo "✅ Activation complete → $systemConfig"
        echo "   Timestamp: $TIMESTAMPS"

        # ====================================================================
        # Post-Activation Comprehensive Diagnostics
        # ====================================================================
        # Verify that the activation actually succeeded and provide clear
        # diagnostics for debugging exit code issues (especially exit code 2
        # from launchctl asuser calls during home-manager activation)

        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Post-activation verification starting..."

        # Check if /run/current-system symlink was updated (proves activation succeeded)
        if [ -L /run/current-system ]; then
          CURRENT_SYSTEM=$(readlink /run/current-system)
          echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] ✓ System activation succeeded"
          echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Current system: $CURRENT_SYSTEM"
        else
          echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] /run/current-system symlink not found" >&2
          echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] Activation may have failed - check logs above" >&2
        fi

        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] ============================================"
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] darwin-rebuild completed"
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] ============================================"
      '';
    };

    # macOS system version (required for nix-darwin)
    stateVersion = 5;
  };
}
