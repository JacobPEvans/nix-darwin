# macbook-m4 Home Configuration
#
# User environment for macbook-m4 host.
# Imports common home-manager modules with host-specific overrides.

{ config, ... }:

{
  imports = [
    # Common home-manager configuration
    ../../modules/home-manager/common.nix

    # Ollama configuration (models on /Volumes/Ollama)
    ../../modules/home-manager/ollama.nix
  ];

  # ==========================================================================
  # Host-Specific Home Settings
  # ==========================================================================
  # Settings unique to this machine's user environment

  # Additional host-specific packages (beyond common)
  # home.packages = with pkgs; [ ];  # Uncomment and add pkgs to args when needed

  # Host-specific symlinks for external volumes
  # NOTE: These symlinks point to data on external volumes.
  # Nix does NOT manage the volume contents - only creates symlinks.
  home.file = {
    # Ollama models symlink managed by modules/home-manager/ollama.nix

    # OrbStack data on dedicated APFS volume
    # Symlinks entire Group Container so ALL OrbStack data lives on volume
    # Volume created by launchd daemon (see modules/darwin/apps/orbstack.nix)
    # Contains: Docker images, containers, volumes, Linux VMs, logs
    # MIGRATION: Stop OrbStack and move existing data before enabling
    "Library/Group Containers/HUAQ24HBR6.dev.orbstack".source =
      config.lib.file.mkOutOfStoreSymlink "/Volumes/ContainerData";
  };

  # Environment variables for external data locations
  home.sessionVariables = {
    # Container data on dedicated volume
    # NOTE: This volume is separate from Ollama
    CONTAINER_DATA = "/Volumes/ContainerData";
  };
}
