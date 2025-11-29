# ubuntu-server Home Configuration
#
# User environment for ubuntu-server host.
# Minimal server configuration without GUI applications.

{ config, pkgs, lib, ... }:

{
  imports = [
    # Common home-manager configuration (shell, git, etc.)
    ../../modules/home-manager/common.nix
  ];

  # ==========================================================================
  # Server-Specific Overrides
  # ==========================================================================

  # Disable GUI applications on server
  programs.vscode.enable = lib.mkForce false;

  # Server-specific packages
  home.packages = with pkgs; [
    # Add server-specific tools here
  ];

  home.stateVersion = "24.05";
}
