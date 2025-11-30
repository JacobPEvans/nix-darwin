# Linux Common Module
#
# Shared home-manager configuration for all Linux hosts.
# This module is imported by Linux host home.nix files.
#
# NOTE: This uses home-manager standalone (not full system management).
# System packages on Linux are managed by apt/dnf/etc.

{ config, pkgs, lib, ... }:

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

  home.packages = with pkgs; [
    # Core CLI tools (same as darwin common)
    bat
    delta
    eza
    fd
    fzf
    htop
    jq
    ncdu
    ripgrep
    tldr
    tree

    # Development tools
    gnupg
  ];

  # ==========================================================================
  # Linux-Specific Settings
  # ==========================================================================

  # XDG directories (Linux standard)
  xdg.enable = true;

  # Session variables for Linux
  home.sessionVariables = {
    # Add Linux-specific environment variables here
  };
}
