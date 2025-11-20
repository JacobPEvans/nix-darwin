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

  # Nix configuration
  nix.settings = {
    experimental-features = "nix-command flakes";
  };

  # macOS system version (required for nix-darwin)
  system.stateVersion = 5;
}
