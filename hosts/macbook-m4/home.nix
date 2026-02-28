# macbook-m4 Home Configuration
#
# User environment for macbook-m4 host.
# Cross-platform settings provided by nix-home (sharedModule).
# AI CLI settings provided by nix-ai (sharedModule).
# This file adds macOS-specific overrides and host-specific settings.

{
  config,
  pkgs,
  lib,
  userConfig,
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

  # WORKAROUND: Disable manpage generation to suppress options.json derivation context warning
  # Upstream: https://github.com/nix-community/home-manager/issues/7935
  # TODO: Re-enable when upstream fixes options.json context in manual.nix
  manual.manpages.enable = false;

  imports = [
    # Activation recovery after login (fixes boot failures)
    ../../modules/home-manager/nix-activation-recovery.nix

    # Raycast script scheduling (refresh-repos LaunchAgent)
    ../../modules/home-manager/raycast-scripts.nix
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
    otel = {
      enable = true;
      # endpoint defaults to http://localhost:30317 (NodePort gRPC)
      logPrompts = true;
      logToolDetails = true;
      resourceAttributes = {
        "host.name" = "macbook-m4";
      };
    };
    cribl.enable = true;
  };

  programs = {
    # Enable activation recovery after login (fixes boot failures)
    # See docs/boot-failure/root-cause.md for why this is needed
    nix-activation-recovery.enable = true;

    # Raycast refresh-repos scheduling (hourly, replaces manual plist)
    raycast-scripts.refreshRepos.enable = true;

    claude = {
      # Disable playwright plugin globally — only useful in specific projects.
      # playwright@claude-skills (skills-only, no MCP) stays enabled.
      plugins.enabled."playwright@claude-plugins-official" = lib.mkForce false;

      # Disable MCP servers that duplicate built-in tools, are demo/test, or are project-specific.
      # Servers remain defined (for type validation) but disabled = true excludes them from ~/.claude.json.
      # Project-specific servers (cribl, terraform, aws) are re-enabled via per-project .mcp.json.
      mcpServers = {
        # Demo/test — not useful in production
        everything.disabled = true;

        # Duplicates built-in Read/Write/Glob/Edit tools
        filesystem.disabled = true;

        # Duplicates built-in WebFetch tool
        fetch.disabled = true;

        # Duplicates built-in git via Bash(git:*)
        git.disabled = true;

        # Duplicates github@claude-plugins-official plugin
        github.disabled = true;

        # Project-specific — available via per-project .mcp.json
        cribl.disabled = true;
        aws.disabled = true;
        terraform.disabled = true;

        # Not actively used — disable until needed
        cloudflare.disabled = true;
        exa.disabled = true;
        firecrawl.disabled = true;
        docker.disabled = true;
      };
    };

    # macOS-specific zsh overrides
    # Base zsh config provided by nix-home (sharedModule).
    # These additions are macOS-specific and merge via NixOS module system.
    zsh = {
      oh-my-zsh.plugins = [
        "macos" # macOS utilities (ofd, cdf, etc.)
      ];

      # macOS-specific shell init (appended after cross-platform initContent from nix-home)
      initContent = lib.mkAfter ''
        # --- API Keys (from macOS Keychain) ---

        _get_keychain_secret() {
          # Fetch a secret from the macOS Keychain by service name.
          # Usage: _get_keychain_secret <service> <account>
          security find-generic-password -s "$1" -a "$2" -w 2>/dev/null || echo ""
        }

        # GitHub - for github@claude-plugins-official MCP server
        export GITHUB_PERSONAL_ACCESS_TOKEN=''${GITHUB_PERSONAL_ACCESS_TOKEN:-"$(_get_keychain_secret 'github-pat' '${userConfig.user.name}')"}

        # Context7 - for context7@claude-plugins-official MCP server
        export CONTEXT7_API_KEY=''${CONTEXT7_API_KEY:-"$(_get_keychain_secret 'CONTEXT7_API_KEY' '${userConfig.user.name}')"}

        unset -f _get_keychain_secret

        # --- macOS setup ---
        source ${./macos-setup.zsh}
      '';
    };
  };

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
    packages = with pkgs; [
      # Terminal & Development
      ghostty-bin # Terminal emulator - needs Full Disk Access for darwin-rebuild
      postman # API development environment - auto-updates disabled (see auto-update-prevention.nix)
      rapidapi # Full-featured HTTP client for testing and describing APIs - auto-updates disabled (see auto-update-prevention.nix)

      # AI IDEs & Tools (nixpkgs - stable TCC paths via copyApps)
      code-cursor # Cursor AI IDE (VS Code fork)
      chatgpt # OpenAI ChatGPT desktop app
      claudebar # Menu bar app for AI coding assistant quota monitoring

      # Communication
      # zoom-us # DISABLED - no longer using Zoom

      # CLI / Media tools (non-GUI, no .app bundle)
      ffmpeg # Complete solution to record, convert and stream audio and video
    ];

    # ========================================================================
    # Host-specific symlinks for external volumes
    # ========================================================================
    # NOTE: These symlinks point to data on external volumes.
    # Nix does NOT manage the volume contents - only creates symlinks.
    file = {
      # Ollama models symlink managed by nix-ai (ollama.nix module)

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
