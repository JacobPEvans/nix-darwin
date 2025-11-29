# proxmox Host Configuration
#
# Proxmox VE server configuration template.
# This is a TEMPLATE for managing a Proxmox host with NixOS.
#
# NOTE: Proxmox runs on Debian, not NixOS directly.
# Options for Nix integration:
# 1. Run NixOS VMs inside Proxmox
# 2. Use home-manager standalone for user environment
# 3. Consider nixos-anywhere for NixOS-on-Proxmox
#
# This template assumes NixOS VM running on Proxmox.

{ config, pkgs, lib, ... }:

{
  imports = [
    # NixOS system modules
    ../../modules/nixos/common.nix
    # ../../modules/nixos/server.nix  # Uncomment when created
  ];

  # ==========================================================================
  # Host-Specific Settings
  # ==========================================================================

  networking.hostName = "proxmox-nixos";

  # Virtualization support (for nested VMs if needed)
  virtualisation = {
    # Enable if running containers on this host
    # docker.enable = true;
    # podman.enable = true;
  };

  # SSH access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Firewall - adjust based on services
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # SSH
      # 8006  # Proxmox web UI (if proxying)
    ];
  };

  # System packages for Proxmox/server management
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    tmux
    qemu      # VM management
    libvirt   # Virtualization API
  ];

  # NixOS state version
  system.stateVersion = "24.05";
}
