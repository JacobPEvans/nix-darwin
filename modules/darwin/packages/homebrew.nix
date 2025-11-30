# Homebrew Configuration
#
# Homebrew is a FALLBACK ONLY for packages not in nixpkgs or severely outdated.
# Prefer nixpkgs for everything.
#
# Update Strategy:
# - autoUpdate = false: Skip slow 45MB index download on every rebuild
# - upgrade = true: Upgrade packages based on cached index
# - To get latest versions: run `brew update` then `darwin-rebuild switch`

{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;   # Don't download 45MB index on every rebuild (fast)
      cleanup = "none";     # Don't remove manually installed packages
      upgrade = true;       # Upgrade packages based on cached index
    };

    taps = [
      # Additional taps if needed
    ];

    brews = [
      # CLI tools (only if not available in nixpkgs)
    ];

    casks = [
      # claude-code: Rapidly-evolving developer tool
      # - Nixpkgs version lags behind releases
      # - Can't auto-update from read-only nix store
      # - Manual upgrade: brew upgrade --cask claude-code
      "claude-code"
    ];

    # Mac App Store apps (requires signed into App Store)
    # Find app IDs: mas search <name> or https://github.com/mas-cli/mas
    masApps = {
      # "App Name" = app_id;
    };
  };
}
