# macbook-m4 Home Configuration
#
# User environment for macbook-m4 host.
# Imports common home-manager modules with host-specific overrides.

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # ==========================================================================
  # macOS Application Management (copyApps for TCC stability)
  # ==========================================================================
  # Use copyApps instead of linkApps to create REAL copies of apps at stable
  # paths in ~/Applications/Home Manager Apps/. This allows macOS TCC
  # (Transparency, Consent, Control) permissions to persist across rebuilds.
  #
  # With linkApps (default), apps symlink to /nix/store paths which change on
  # every rebuild, invalidating TCC permissions (camera, mic, screen recording).
  #
  # Trade-off: Uses more disk space (~100MB per app) but TCC permissions persist.
  #
  # See: https://github.com/nix-community/home-manager/issues/8336
  targets.darwin = {
    copyApps.enable = true;
    linkApps.enable = false;
  };

  imports = [
    # Common home-manager configuration
    ../../modules/home-manager/common.nix

    # Ollama configuration (models on /Volumes/Ollama)
    ../../modules/home-manager/ollama.nix

    # Activation recovery after login (fixes boot failures)
    ../../modules/home-manager/nix-activation-recovery.nix

    # Raycast script scheduling (refresh-repos LaunchAgent)
    ../../modules/home-manager/raycast-scripts.nix

    # tmux configuration (session persistence, agent teams)
    ../../modules/home-manager/tmux.nix
  ];

  # ==========================================================================
  # Auto-Update Cache Cleanup (for Nix-managed apps)
  # ==========================================================================
  # Clean Squirrel/ShipIt and Sparkle updater caches on every rebuild.
  # This complements the auto-update-prevention.nix module by removing
  # leftover updater state that could interfere with Nix-managed versions.
  home.activation.cleanAutoUpdateCaches = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Clean Squirrel/ShipIt and Sparkle updater caches
    $DRY_RUN_CMD rm -rf "$HOME/Library/Caches/com.postmanlabs.mac.ShipIt" 2>/dev/null || true
    $DRY_RUN_CMD rm -rf "$HOME/Library/Caches/com.luckymarmot.Paw/org.sparkle-project.Sparkle" 2>/dev/null || true
  '';

  # ==========================================================================
  # Host-Specific Home Settings
  # ==========================================================================
  # Settings unique to this machine's user environment

  # Enable monitoring infrastructure (K8s manifests, helper scripts)
  monitoring = {
    enable = true;
    kubernetes.enable = true;
    otel.enable = true;
    cribl.enable = true;
  };

  # Enable activation recovery after login (fixes boot failures)
  # See docs/boot-failure/root-cause.md for why this is needed
  programs.nix-activation-recovery.enable = true;

  # Raycast refresh-repos scheduling (hourly, replaces manual plist)
  programs.raycast-scripts.refreshRepos.enable = true;

  home = {
    # ========================================================================
    # TCC-Sensitive GUI Applications (using copyApps for stable paths)
    # ========================================================================
    # These apps need macOS TCC (Transparency Consent Control) permissions
    # for camera, microphone, screen recording, etc.
    #
    # With targets.darwin.copyApps enabled (see above), apps in home.packages
    # are COPIED to ~/Applications/Home Manager Apps/ with STABLE paths that
    # persist TCC permissions across darwin-rebuild.
    #
    # This is better than mac-app-util trampolines because:
    # - Binary paths are stable (not /nix/store which changes on rebuild)
    # - TCC permissions granted to the app persist
    # - No wrapper scripts - actual app copies
    #
    # Trade-off: Uses more disk space (~100MB per app) but TCC works correctly.
    #
    # NOTE: OrbStack managed via programs.orbstack module at system-level.
    # See hosts/macbook-m4/default.nix for OrbStack configuration.
    packages =
      (with pkgs; [
        # Terminal & Development
        ghostty-bin # Terminal emulator - needs Full Disk Access for darwin-rebuild
        postman # API development environment - auto-updates disabled (see auto-update-prevention.nix)
        rapidapi # Full-featured HTTP client for testing and describing APIs - auto-updates disabled (see auto-update-prevention.nix)

        # AI IDEs & Tools (nixpkgs - stable TCC paths via copyApps)
        antigravity # Google's AI-powered IDE (Gemini 3)
        code-cursor # Cursor AI IDE (VS Code fork)
        chatgpt # OpenAI ChatGPT desktop app
        claudebar # Menu bar app for AI coding assistant quota monitoring

        # Communication
        # zoom-us # DISABLED - no longer using Zoom
      ])
      # CLI / Media tools (non-GUI, no .app bundle)
      ++ (with pkgs; [
        ffmpeg # Complete solution to record, convert and stream audio and video
      ])
      # AI Development Tools (linters, formatters, analyzers)
      # See modules/home-manager/ai-cli/ai-tools.nix for package definitions
      ++ (import ../../modules/home-manager/ai-cli/ai-tools.nix { inherit pkgs; }).packages;

    # ========================================================================
    # Host-specific symlinks for external volumes
    # ========================================================================
    # NOTE: These symlinks point to data on external volumes.
    # Nix does NOT manage the volume contents - only creates symlinks.
    file = {
      # Ollama models symlink managed by modules/home-manager/ollama.nix

      # OrbStack data on dedicated APFS volume
      # Symlinks entire Group Container so ALL OrbStack data lives on volume
      # Volume created by launchd daemon (see modules/darwin/apps/orbstack.nix)
      # Contains: Docker images, containers, volumes, Linux VMs, logs
      # MIGRATION: Stop OrbStack and move existing data before enabling
      "Library/Group Containers/HUAQ24HBR6.dev.orbstack".source =
        config.lib.file.mkOutOfStoreSymlink "/Volumes/ContainerData";
    };

    # ========================================================================
    # Environment variables for external data locations
    # ========================================================================
    sessionVariables = {
      # Container data on dedicated volume
      # NOTE: This volume is separate from Ollama
      CONTAINER_DATA = "/Volumes/ContainerData";
    };
  };
}
