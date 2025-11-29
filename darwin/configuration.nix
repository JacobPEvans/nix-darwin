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
    gemini-cli      # Google's Gemini CLI
    gh              # GitHub CLI
    tree
    git
    gnupg
    nodejs_latest   # Node.js runtime
    vim
    vscode          # Visual Studio Code editor
  ];

  # Homebrew as FALLBACK ONLY for packages not in nixpkgs or severely outdated
  # Prefer nixpkgs for everything - only use homebrew when absolutely necessary
  # Packages upgraded on darwin-rebuild via onActivation.upgrade = true
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;    # Update homebrew itself on darwin-rebuild
      cleanup = "none";     # Don't remove manually installed packages
      upgrade = true;       # Upgrade outdated packages on darwin-rebuild
    };
    taps = [
      # "homebrew/cask"   # Example: additional taps
    ];
    brews = [
      # CLI tools (only if not available in nixpkgs)
    ];
    casks = [
      # GUI applications (only if not available in nixpkgs)

      # claude-code: Rapidly-evolving developer tool that benefits from auto-updates.
      # Nixpkgs version lags behind and can't auto-update from read-only nix store.
      # Exception approved: Frequently updated developer tool with new features.
      "claude-code"
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

