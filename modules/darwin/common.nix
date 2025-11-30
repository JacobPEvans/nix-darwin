{ pkgs, ... }:

let
  userConfig = import ../../lib/user-config.nix;
in
{
  imports = [
    # System settings
    ./dock.nix
    ./finder.nix
    ./keyboard.nix
    ./trackpad.nix
    ./system-ui.nix

    # Packages (split into categories)
    ./packages
  ];

  # ==========================================================================
  # Nixpkgs Configuration
  # ==========================================================================
  nixpkgs.config.allowUnfree = true;

  # ==========================================================================
  # User Configuration
  # ==========================================================================
  users.users.${userConfig.user.name} = {
    name = userConfig.user.name;
    home = "/Users/${userConfig.user.name}";
  };

  # Required for nix-darwin with Determinate Nix
  system.primaryUser = userConfig.user.name;

  # ==========================================================================
  # Shell & System Settings
  # ==========================================================================
  programs.zsh.enable = true;

  # Disable nix-darwin's Nix management (using Determinate Nix installer instead)
  nix.enable = false;

  # Disable documentation to suppress builtins.toFile warnings
  documentation.enable = false;

  # macOS system version (required for nix-darwin)
  system.stateVersion = 5;
}
