# Ubuntu Server Home Configuration
#
# User environment managed by home-manager standalone.
# System packages are managed by apt (see default.nix for notes).

{
  config,
  pkgs,
  lib,
  ...
}:

let
  userConfig = import ../../lib/user-config.nix;
  serverConfig = import ../../lib/server-config.nix;
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
  home.username = userConfig.user.name;
  home.homeDirectory = "/home/${userConfig.user.name}";
  home.stateVersion = "24.05";

  # ==========================================================================
  # Ubuntu Server-Specific Settings
  # ==========================================================================

  # Disable GUI applications on server
  programs.vscode.enable = lib.mkForce false;

  # Ubuntu-specific packages (beyond common)
  home.packages = with pkgs; [
    # Add Ubuntu-specific tools here if needed
  ];
}
