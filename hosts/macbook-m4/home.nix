# macbook-m4 Home Configuration
#
# User environment for macbook-m4 host.
# Imports common home-manager modules with host-specific overrides.

{ config, pkgs, ... }:

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
  home = {
    # ========================================================================
    # TCC-Sensitive GUI Applications (require proper trampolines)
    # ========================================================================
    # These apps need macOS TCC (Transparency Consent Control) permissions
    # for camera, microphone, screen recording, etc.
    #
    # IMPORTANT: Apps in home.packages get REAL trampolines via mac-app-util
    # that persist TCC permissions across darwin-rebuild. Apps in system
    # packages (environment.systemPackages) do NOT get stable trampolines
    # that persist TCC permissions; instead they get hard copies in
    # /Applications/Nix Apps/.
    #
    # Trampolines location: ~/Applications/Home Manager Trampolines/
    #
    # NOTE: OrbStack moved to system-level installation via
    # programs.orbstack.package.enable in default.nix
    # See hosts/macbook-m4/default.nix for OrbStack configuration
    packages = with pkgs; [
      ghostty-bin # Terminal emulator - needs Full Disk Access for darwin-rebuild
      zoom-us # Video conferencing - needs camera/mic TCC permissions
    ];

    # ========================================================================
    # Host-specific symlinks for external volumes
    # ========================================================================
    # NOTE: These symlinks point to data on external volumes.
    # Nix does NOT manage the volume contents - only creates symlinks.
    file = {
      # Ollama models symlink managed by modules/home-manager/ollama.nix

      # OrbStack data on dedicated APFS volume
      # Symlinks entire Group Container so ALL OrbStack data lives on volume
      # Volume created by launchd daemon (see modules/darwin/apps/orbstack.nix)
      # Contains: Docker images, containers, volumes, Linux VMs, logs
      # MIGRATION: Stop OrbStack and move existing data before enabling
      "Library/Group Containers/HUAQ24HBR6.dev.orbstack".source =
        config.lib.file.mkOutOfStoreSymlink "/Volumes/ContainerData";
    };

    # ========================================================================
    # Environment variables for external data locations
    # ========================================================================
    sessionVariables = {
      # Container data on dedicated volume
      # NOTE: This volume is separate from Ollama
      CONTAINER_DATA = "/Volumes/ContainerData";
    };
  };
}
