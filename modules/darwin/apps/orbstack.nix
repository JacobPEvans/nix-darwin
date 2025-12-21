# OrbStack Configuration Module (Darwin)
#
# Manages macOS-specific OrbStack configuration:
# - System-level application installation (optional)
# - Dedicated APFS data volume (created at boot via launchd)
#
# Installation Patterns:
#
# 1. SYSTEM-LEVEL (Recommended for single-user machines):
#    programs.orbstack = {
#      enable = true;
#      package.enable = true;  # Install system-wide
#      dataVolume = {
#        enable = true;
#        name = "ContainerData";
#        apfsContainer = "disk3";  # Find with: diskutil apfs list
#      };
#    };
#
#    Pros: Machine-wide service, integrates with nix-darwin
#    Cons: TCC permissions may reset on rebuilds (requires re-granting)
#    App location: /Applications/Nix Apps/OrbStack.app
#
# 2. PER-USER (For multi-user machines or when TCC stability is critical):
#    In hosts/<host>/default.nix:
#      programs.orbstack = {
#        enable = true;
#        package.enable = false;  # Don't install system-wide
#        dataVolume = { ... };    # Volume is still system-wide
#      };
#
#    In hosts/<host>/home.nix:
#      home.packages = [ pkgs.orbstack ];  # Install per-user
#
#    Pros: mac-app-util provides stable trampolines for TCC permissions
#    Cons: Requires per-user configuration for each user
#    App location: ~/Applications/Home Manager Trampolines/OrbStack.app
#
# The data volume symlink is managed by home-manager in hosts/<host>/home.nix
# using mkOutOfStoreSymlink (see Ollama pattern for example):
#   home.file."Library/Group Containers/HUAQ24HBR6.dev.orbstack".source =
#     config.lib.file.mkOutOfStoreSymlink "/Volumes/ContainerData";
#
# Migration (one-time setup):
#   1. Stop OrbStack completely (orb shutdown or quit app)
#   2. Run darwin-rebuild switch to create the volume
#   3. Move existing data: mv ~/Library/Group\ Containers/HUAQ24HBR6.dev.orbstack/* /Volumes/ContainerData/
#   4. Remove original directory: rm -rf ~/Library/Group\ Containers/HUAQ24HBR6.dev.orbstack
#   5. Then add symlink in home.nix and rebuild
#
# Why a separate volume?
# - OrbStack stores data in ~/Library/Group Containers/... by default
# - A dedicated APFS volume provides better disk space visibility
# - APFS volumes share container space dynamically (no wasted pre-allocation)
#
# Note: OrbStack doesn't natively support custom data directories.
# If it did, we would use: programs.orbstack.dataDir = "/Volumes/ContainerData";

{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.programs.orbstack;
  volumeScript = ./scripts/ensure-apfs-volume.sh;
in
{
  options.programs.orbstack = {
    enable = lib.mkEnableOption "OrbStack configuration";

    package = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Install OrbStack as a system-level application.

          When enabled: App installed to /Applications/Nix Apps/OrbStack.app
          When disabled: Install via home.packages for stable TCC permissions

          See module documentation for detailed comparison of installation patterns.
        '';
      };
    };

    dataVolume = {
      enable = lib.mkEnableOption "dedicated APFS volume for OrbStack data";

      name = lib.mkOption {
        type = lib.types.str;
        default = "ContainerData";
        description = "Name of the APFS volume for OrbStack data.";
      };

      apfsContainer = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          APFS container identifier where the volume will be created.
          Find yours with: diskutil apfs list
          Usually "disk3" on Apple Silicon Macs with single internal storage.
        '';
        example = "disk3";
      };

      groupContainerId = lib.mkOption {
        type = lib.types.str;
        default = "HUAQ24HBR6.dev.orbstack";
        description = ''
          OrbStack's App Group Container identifier.
          Used in documentation; the actual symlink is configured in home-manager.
          This value is consistent across OrbStack installations.
        '';
        internal = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Validate apfsContainer is set when dataVolume is enabled
    assertions = lib.mkIf cfg.dataVolume.enable [
      {
        assertion = cfg.dataVolume.apfsContainer != "";
        message = "programs.orbstack.dataVolume.apfsContainer must be set. Find yours with: diskutil apfs list";
      }
    ];

    # Install OrbStack system-wide if package.enable is true
    environment.systemPackages = lib.mkIf cfg.package.enable [ pkgs.orbstack ];

    # Launchd daemon to ensure APFS volume exists at boot
    launchd.daemons.orbstack-volume = lib.mkIf cfg.dataVolume.enable {
      serviceConfig = {
        Label = "com.nix-darwin.orbstack-volume";
        ProgramArguments = [
          "/bin/bash"
          "${volumeScript}"
          cfg.dataVolume.name
          cfg.dataVolume.apfsContainer
        ];
        RunAtLoad = true;
        LaunchOnlyOnce = true;
        UserName = "root";
        GroupName = "wheel";
        StandardOutPath = "/var/log/orbstack-volume.log";
        StandardErrorPath = "/var/log/orbstack-volume.log";
      };
    };
  };
}
