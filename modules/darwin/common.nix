{
  pkgs,
  lib,
  unstablePkgs,
  ...
}:

let
  userConfig = import ../../lib/user-config.nix;
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
    (import ../../overlays/macos-apps.nix)
    # Fast-moving packages from nixpkgs-unstable for version currency
    # Stable branches (25.11) only get security fixes, not version bumps
    # Policy: Add packages here that release faster than the stable branch updates
    #
    # GUI apps on STABLE (intentional): bitwarden-desktop, chatgpt, code-cursor,
    # postman, rapidapi, raycast, swiftbar
    (_final: _prev: {
      inherit (unstablePkgs)
        # GUI applications (need unstable for fast upstream releases)
        ghostty-bin
        ollama

        # AI CLI tools (fast-moving, stable lags behind upstream)
        github-mcp-server
        terraform-mcp-server

        # Speech-to-text / AI tools (fast-moving releases)
        whisper-cpp # Local speech-to-text (OpenAI Whisper C++ port, CoreML/Metal)
        # NOTE: open-webui intentionally omitted — broken on darwin:
        #   open-webui → pgvector → postgresql-test-hook (marked broken on darwin)
        #   Installed via pipx in home-manager activation (see modules/home-manager/common.nix)
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
  # NOTE: User dev tools (bat, ripgrep, jq, etc.) provided by nix-home via home.packages
  environment.systemPackages = with pkgs; [
    # ========================================================================
    # Core CLI tools (bootstrapping - needed before home-manager)
    # ========================================================================
    git
    gnupg
    vim

    # ========================================================================
    # macOS-specific system tools
    # ========================================================================
    mas # Mac App Store CLI
    mactop # Real-time Apple Silicon CPU/GPU/ANE/thermal monitoring

    # ========================================================================
    # Network & process tools
    # ========================================================================
    ngrep # Network packet grep (useful for debugging)
    procps # Process utilities including pgrep, pkill

    # ========================================================================
    # Audio libraries (system-level dependencies)
    # ========================================================================
    sox # Audio recording, conversion, and effects (Sound eXchange)
    portaudio # Cross-platform audio I/O library

    # ========================================================================
    # AI/ML system services
    # ========================================================================
    ollama # LLM runtime (models on /Volumes/Ollama/models)
    whisper-cpp # Local speech-to-text (OpenAI Whisper C++ port, CoreML/Metal)
    openai-whisper # Original OpenAI Whisper (Python, GPU/CPU, broader model support)

    # ========================================================================
    # GUI applications (system-level, in /Applications/Nix Apps/)
    # ========================================================================
    bitwarden-desktop # Password manager desktop app
    raycast # Productivity launcher (replaces Spotlight)
    swiftbar # Menu bar customization (auto-claude status)
  ];

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
