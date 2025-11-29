# proxmox Home Configuration
#
# User environment for proxmox host (NixOS VM on Proxmox).
# Minimal server configuration for virtualization management.

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
    # Virtualization tools
    # virtmanager  # GUI - only if X11 available
  ];

  home.stateVersion = "24.05";
}
