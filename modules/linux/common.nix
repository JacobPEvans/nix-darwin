# Linux Common Module
#
# Shared home-manager configuration for all Linux hosts.
# This module is imported by Linux host home.nix files.
#
# NOTE: This uses home-manager standalone (not full system management).
# System packages on Linux are managed by apt/dnf/etc.

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Universal packages (pre-commit, linters) shared across all systems
  commonPackages = import ../common/packages.nix { inherit pkgs; };
in
{
  # ==========================================================================
  # Linux-Specific Home-Manager Settings
  # ==========================================================================

  # Linux-specific shell configuration
  programs.zsh.oh-my-zsh.plugins = lib.mkForce [
    "git"
    "docker"
    "z"
    "colored-man-pages"
    # "macos" not applicable on Linux
  ];

  # ==========================================================================
  # Linux User Packages (via home-manager)
  # ==========================================================================
  # These are installed to user profile, not system-wide.
  # For system packages, use apt/dnf on the host.

  home.packages =
    commonPackages
    ++ (with pkgs; [
      # Core CLI tools (same as darwin common)
      bat
      delta
      eza
      fd
      fzf
      htop
      jq
      yq
      ncdu
      ripgrep
      tldr
      tree

      # Development tools
      gnupg
    ]);

  # ==========================================================================
  # Linux-Specific Settings
  # ==========================================================================

  # XDG directories (Linux standard)
  xdg.enable = true;

  # Session variables for Linux
  home.sessionVariables = {
    # Add Linux-specific environment variables here
  };

  # ==========================================================================
  # Nix Configuration
  # ==========================================================================

  # Automatic Garbage Collection
  # Removes old Nix store generations to free disk space without manual intervention
  # Uses home-manager's nix.gc for standalone Nix installations on Linux
  nix.gc = {
    # Enable automatic garbage collection
    automatic = true;

    # Run weekly - balances disk space with keeping recent builds
    frequency = "weekly";

    # Options passed to nix-collect-garbage
    # --delete-older-than 30d: Keep generations from last 30 days
    # Provides rollback capability for recent changes while cleaning old builds
    options = "--delete-older-than 30d";
  };

  # Additional Nix settings for garbage collection behavior
  nix.settings = {
    # Automatically optimize store (hard-link identical files) during GC
    auto-optimise-store = true;
  };
}
