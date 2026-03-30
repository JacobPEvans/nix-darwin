# macbook-m4 Host Configuration
#
# Apple Silicon MacBook Pro (M4 Max, 128GB RAM)
# Primary development machine using nix-darwin
#
# This file imports darwin modules and configures host-specific settings.

{ pkgs, ... }:

let
  # User-specific configuration (hostname, identity, etc.)
  userConfig = import ../../lib/user-config.nix;
in
{
  imports = [
    # Darwin system modules
    ../../modules/darwin/common.nix
  ];

  # ==========================================================================
  # Host-Specific Settings
  # ==========================================================================
  # Settings that are unique to this specific machine
  # Hostname from lib/user-config.nix

  networking.hostName = userConfig.host.name;

  # ==========================================================================
  # System Services
  # ==========================================================================

  # SSH/Remote Login
  # Enables macOS Remote Login via launchd (System Settings > General > Sharing)
  # Allows SSH access to this development machine
  services.openssh.enable = true;

  # ==========================================================================
  # Programs
  # ==========================================================================

  programs = {
    # --- OrbStack ---
    # Container runtime as system-level application
    # - System-wide installation via nix-darwin
    # - Dedicated APFS volume for data storage
    # - Data symlink configured in home.nix using mkOutOfStoreSymlink
    #
    # NOTE: package.enable = true installs OrbStack system-wide
    # TCC permissions (Docker/Linux VM access) may need re-granting after rebuilds
    # For TCC stability, set package.enable = false and add to home.packages instead
    orbstack = {
      enable = true;
      # package.enable = false: OrbStack is installed via Homebrew cask (greedy = true)
      # in modules/darwin/homebrew.nix. Homebrew installs to /Applications/ as a real
      # copy, so TCC permissions (Docker socket, Linux VM) persist across darwin-rebuild.
      # Previously, nixpkgs installed a symlink to a /nix/store path that changes on
      # every rebuild, forcing TCC re-granting each time.
      package.enable = false;
      dataVolume = {
        enable = true;
        name = "ContainerData";
        apfsContainer = "disk3"; # Find with: diskutil apfs list
      };
    };

    # --- File Extension Mappings ---
    # Custom file extensions recognized as tar.gz archives
    # Enables Finder auto-extract and shell autocomplete
    file-extensions = {
      enable = true;
    };

    # --- Cribl Edge ---
    # Log collection agent managed by Cribl Cloud
    # Installed externally via .pkg — Nix manages the LaunchDaemon and ACLs
    cribl-edge = {
      enable = true;
      acls = [
        "/var/log" # system.log, install.log, wifi.log
        "/var/log/asl" # Apple System Log archives
        "/var/log/DiagnosticMessages" # system diagnostics
        "/var/audit" # BSM audit trail (login, sudo, file access)
        "/Library/Logs" # system-level application logs
        "/Library/Logs/DiagnosticReports" # crash reports
      ];
      packs = {
        cc-edge-macos-power = pkgs.fetchzip {
          url = "https://github.com/JacobPEvans/cc-edge-macos-power/releases/download/v1.0.0/cc-edge-macos-power-v1.0.0.crbl";
          extension = "tar.gz";
          hash = "sha256-fzuekOUHCjxajzozGDhAk1jQHP6bLatTvSfF2fI0afA=";
          stripRoot = false;
        };
      };
    };

    # --- Streamline Login Items ---
    # Persistently disable unwanted updaters and remove junk plists.
    # Edit these lists to add/remove services — enforced on every rebuild.
    streamline-login = {
      enable = true;

      # Junk/dead plists to delete from ~/Library/LaunchAgents/
      removePlists = [
        "com.google.keystone.agent.plist" # Legacy Google Keystone (empty, replaced by GoogleUpdater)
        "com.google.keystone.xpcservice.plist" # Legacy Google Keystone (empty)
        "screenpipe.plist" # Screenpipe auto-start (app stays installed)
      ];

      # User-domain services to disable (updaters, redundant apps, broken daemons)
      disableUserServices = [
        "com.google.GoogleUpdater.wake" # Google hourly updater
        "us.zoom.updater" # Zoom hourly updater
        "us.zoom.updater.login.check" # Zoom login check at login
        "com.ollama.ollama" # Redundant — vllm-mlx is primary inference server
        # Boot-time race condition daemons — crash-loop before dependencies ready,
        # corrupt WindowServer client dispatch table, cause sustained UI lag/freezes
        "com.apple.universalaccessd" # No accessibility features enabled
        "com.apple.macos.studentd" # Classroom daemon, no MDM enrollment
        "com.apple.passd" # Apple Wallet not used
      ];

      # System-domain services to disable
      disableSystemServices = [
        "com.google.GoogleUpdater.wake.system" # Google system updater (hourly)
        "com.duosecurity.duoappupdater" # Duo updater (every 10 minutes)
        "us.zoom.ZoomDaemon" # Zoom privileged helper daemon
      ];
    };
  };

  # --- Energy & Sleep Configuration ---
  system.energy = {
    enable = true;
    displaysleep = 30; # Display sleeps after 30 minutes
    sleep = {
      ac = 0; # Never sleep when plugged in (AC power)
      battery = 60; # Sleep after 1 hour on battery
    };
    # Set disksleep to non-zero when battery sleep is non-zero (Apple best practice)
    # This ensures optimal power state transition on battery (Safe Sleep requires this)
    disksleep = 10; # Disk optimizes power after 10 minutes (before system sleep at 60)
    wakeOnMagicPacket = true;
    autoRestartOnPowerLoss = true;
  };
}
