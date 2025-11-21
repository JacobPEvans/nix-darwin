{ pkgs, ... }:

{
  # User configuration
  users.users.jevans = {
    name = "jevans";
    home = "/Users/jevans";
  };

  # Required for nix-darwin with Determinate Nix
  system.primaryUser = "jevans";

  # System packages from nixpkgs
  # All packages should come from nixpkgs - homebrew is fallback only
  environment.systemPackages = with pkgs; [
    claude-code     # Anthropic's AI coding assistant
    gemini-cli      # Google's Gemini CLI
    gh              # GitHub CLI
    git
    gnupg
    nodejs_latest   # Node.js runtime
    vim
  ];

  # Homebrew as FALLBACK ONLY for packages not in nixpkgs or severely outdated
  # Prefer nixpkgs for everything - only use homebrew when absolutely necessary
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;   # Don't auto-update homebrew on rebuild
      cleanup = "none";     # Don't remove manually installed packages
      upgrade = false;      # Don't auto-upgrade packages
    };
    taps = [
      # "homebrew/cask"   # Example: additional taps
    ];
    brews = [
      # CLI tools (only if not available in nixpkgs)
    ];
    casks = [
      # GUI applications (only if not available in nixpkgs)
    ];
  };

  # Enable zsh
  programs.zsh.enable = true;

  # Disable nix-darwin's Nix management (using Determinate Nix installer instead)
  nix.enable = false;

  # Disable documentation to suppress builtins.toFile warnings
  documentation.enable = false;

  # macOS system version (required for nix-darwin)
  system.stateVersion = 5;
}
