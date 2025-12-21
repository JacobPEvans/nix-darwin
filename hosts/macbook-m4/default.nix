# macbook-m4 Host Configuration
#
# Apple Silicon MacBook Pro (M4 Max, 128GB RAM)
# Primary development machine using nix-darwin
#
# This file imports darwin modules and configures host-specific settings.

{ pkgs, ... }:

let
  # User-specific configuration (hostname, identity, etc.)
  userConfig = import ../../lib/user-config.nix;
in
{
  imports = [
    # Darwin system modules
    ../../modules/darwin/common.nix
  ];

  # ==========================================================================
  # Host-Specific Settings
  # ==========================================================================
  # Settings that are unique to this specific machine
  # Hostname from lib/user-config.nix

  networking.hostName = userConfig.host.name;

  # ==========================================================================
  # System Services
  # ==========================================================================

  # SSH/Remote Login
  # Enables macOS Remote Login via launchd (System Settings > General > Sharing)
  # Allows SSH access to this development machine
  services.openssh.enable = true;

  # ==========================================================================
  # OrbStack Configuration
  # ==========================================================================
  # Container runtime with dedicated APFS volume for data storage
  # Data symlink configured in home.nix using mkOutOfStoreSymlink

  programs.orbstack = {
    enable = true;
    dataVolume = {
      enable = true;
      name = "ContainerData";
      apfsContainer = "disk3"; # Find with: diskutil apfs list
    };
  };

  # ==========================================================================
  # File Extension Mappings
  # ==========================================================================
  # Custom file extensions recognized as tar.gz archives
  # Enables Finder auto-extract and shell autocomplete

  programs.file-extensions = {
    enable = true;
    # Default mappings for .spl and .crbl are already configured
    # Add more custom mappings here if needed:
    # customMappings = {
    #   ".spl" = "public.tar-archive";
    #   ".crbl" = "public.tar-archive";
    #   ".custom" = "public.tar-archive";
    # };
  };

  # Machine-specific packages (if any beyond common)
  # environment.systemPackages = with pkgs; [ ];
}
