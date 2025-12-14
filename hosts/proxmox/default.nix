# Proxmox Server System Notes
#
# Proxmox VE runs on Debian. System-level configuration is managed
# through the Proxmox web UI and Debian's apt package manager.
#
# For user environment, see home.nix (managed by home-manager).

{ }

# ==========================================================================
# Host Information
# ==========================================================================
#
# Hostname: ${serverConfig.proxmox.hostname} (pve)
# Web UI Port: ${toString serverConfig.proxmox.webUIPort} (8006)
#
# ==========================================================================
# Manual System Setup (not Nix-managed)
# ==========================================================================
#
# 1. Install Nix on Proxmox host (Determinate installer):
#    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh
#
# 2. Install home-manager (use username from lib/user-config.nix):
#    nix run home-manager -- switch --flake .#<username>
#
# 3. Firewall (ensure these ports are open):
#    - SSH: 22/tcp
#    - Proxmox Web UI: 8006/tcp
#
# 4. Proxmox-specific setup:
#    - VMs and containers managed via Proxmox web UI
#    - Storage configuration via Proxmox
#    - Network configuration via Proxmox
