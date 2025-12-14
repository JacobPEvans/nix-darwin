# Ubuntu Server System Notes
#
# Ubuntu uses apt for system package management.
# User environment is managed by home-manager (see home.nix).

{ }

# ==========================================================================
# Host Information
# ==========================================================================
#
# Hostname: ${serverConfig.ubuntu.hostname}
# SSH Port: ${toString serverConfig.common.sshPort}
#
# ==========================================================================
# Manual System Setup (not Nix-managed)
# ==========================================================================
#
# 1. Install Nix (Determinate installer recommended):
#    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh
#
# 2. Install home-manager (use username from lib/user-config.nix):
#    nix run home-manager -- switch --flake .#<username>
#
# 3. System packages (via apt):
#    sudo apt update && sudo apt install -y openssh-server
#
# 4. Firewall (via ufw):
#    sudo ufw allow 22/tcp
#    sudo ufw enable
