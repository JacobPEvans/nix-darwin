# macbook-m4 Home Configuration
#
# User environment for macbook-m4 host.
# Imports common home-manager modules with host-specific overrides.

{ config, pkgs, ... }:

{
  imports = [
    # Common home-manager configuration
    ../../modules/home-manager/common.nix
  ];

  # ==========================================================================
  # Host-Specific Home Settings
  # ==========================================================================
  # Settings unique to this machine's user environment

  # Additional host-specific packages (beyond common)
  # home.packages = with pkgs; [ ];

  # Host-specific symlinks for external volumes
  # NOTE: These symlinks point to data on external volumes.
  # Nix does NOT manage the volume contents - only creates symlinks.
  home.file = {
    # Ollama models on dedicated external volume
    # CRITICAL: 692GB+ of models - NEVER delete /Volumes/Ollama
    ".ollama/models".source = config.lib.file.mkOutOfStoreSymlink "/Volumes/Ollama/models";
  };

  # Environment variables for external data locations
  home.sessionVariables = {
    # Container data on dedicated volume
    # NOTE: This volume is separate from Ollama
    CONTAINER_DATA = "/Volumes/ContainerData";
  };
}
