# ubuntu-server Host Configuration
#
# Standard Ubuntu/NixOS server configuration template.
# This is a TEMPLATE - customize for your specific server.
#
# NOTE: This configuration is for NixOS, not Ubuntu directly.
# For Ubuntu, you would use home-manager standalone or convert to NixOS.

{ config, pkgs, lib, ... }:

{
  imports = [
    # NixOS system modules
    ../../modules/nixos/common.nix
  ];

  # ==========================================================================
  # Host-Specific Settings
  # ==========================================================================

  networking.hostName = "ubuntu-server";

  # SSH access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # System packages for server
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    tmux
  ];

  # NixOS state version
  system.stateVersion = "24.05";
}
