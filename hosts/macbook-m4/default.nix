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
  # OrbStack Configuration
  # ==========================================================================
  # Container runtime as system-level application
  # - System-wide installation via nix-darwin
  # - Dedicated APFS volume for data storage
  # - Data symlink configured in home.nix using mkOutOfStoreSymlink
  #
  # NOTE: package.enable = true installs OrbStack system-wide
  # TCC permissions (Docker/Linux VM access) may need re-granting after rebuilds
  # For TCC stability, set package.enable = false and add to home.packages instead

  programs.orbstack = {
    enable = true;
    package.enable = true; # Install system-wide (machine-level service)
    dataVolume = {
      enable = true;
      name = "ContainerData";
      apfsContainer = "disk3"; # Find with: diskutil apfs list
    };
  };

  # ==========================================================================
  # File Extension Mappings
  # ==========================================================================
  # Custom file extensions recognized as tar.gz archives
  # Enables Finder auto-extract and shell autocomplete

  programs.file-extensions = {
    enable = true;
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
