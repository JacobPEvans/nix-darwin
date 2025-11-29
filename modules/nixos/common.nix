# NixOS Common Module
#
# Shared NixOS configuration for all Linux hosts.
# This module is imported by all NixOS host configurations.
#
# NOTE: This is a TEMPLATE for future NixOS hosts.
# The current primary host (macbook-m4) uses nix-darwin, not NixOS.

{ config, pkgs, lib, ... }:

{
  # ==========================================================================
  # Nix Settings
  # ==========================================================================

  nix = {
    settings = {
      # Enable flakes
      experimental-features = [ "nix-command" "flakes" ];

      # Optimize storage
      auto-optimise-store = true;

      # Trusted users
      trusted-users = [ "root" "@wheel" ];
    };

    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # ==========================================================================
  # Base System Configuration
  # ==========================================================================

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Timezone (override per-host if needed)
  time.timeZone = "America/New_York";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";

  # ==========================================================================
  # Common System Packages
  # ==========================================================================

  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    vim
    tree
    ripgrep
    curl
    wget
    htop

    # Development
    gnupg
  ];

  # ==========================================================================
  # Common Services
  # ==========================================================================

  # Enable SSH (can be disabled per-host)
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      PermitRootLogin = lib.mkDefault "no";
    };
  };

  # ==========================================================================
  # Security
  # ==========================================================================

  # Enable firewall by default
  networking.firewall.enable = lib.mkDefault true;

  # Sudo configuration
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };
}
