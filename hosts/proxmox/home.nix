# Proxmox Server Home Configuration
#
# User environment managed by home-manager standalone.
# Proxmox system is managed via web UI and apt.

{
  config,
  pkgs,
  lib,
  ...
}:

let
  userConfig = import ../../lib/user-config.nix;
in
{
  # ==========================================================================
  # Module Imports
  # ==========================================================================
  imports = [
    # Cross-platform common (shell, git, etc.)
    ../../modules/home-manager/common.nix

    # Linux-specific common (packages, XDG, etc.)
    ../../modules/linux/common.nix
  ];

  # ==========================================================================
  # Home-Manager Required Settings
  # ==========================================================================
  home = {
    username = userConfig.user.name;
    homeDirectory = "/home/${userConfig.user.name}";
    stateVersion = "24.05";

    # Proxmox-specific packages (beyond common)
    packages = with pkgs; [
      # Add Proxmox-specific tools here if needed
    ];
  };

  # ==========================================================================
  # Proxmox-Specific Settings
  # ==========================================================================

  # Disable GUI applications on server
  programs.vscode.enable = lib.mkForce false;
}
