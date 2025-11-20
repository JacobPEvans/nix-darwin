{ pkgs, ... }:

{
  # User configuration
  users.users.jevans = {
    name = "jevans";
    home = "/Users/jevans";
  };

  # Minimal system packages
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  # Enable zsh
  programs.zsh.enable = true;

  # Disable nix-darwin's Nix management (using Determinate Nix installer instead)
  nix.enable = false;

  # macOS system version (required for nix-darwin)
  system.stateVersion = 5;
}
