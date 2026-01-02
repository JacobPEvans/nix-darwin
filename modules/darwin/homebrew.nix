# Homebrew Configuration
#
# Homebrew is a FALLBACK ONLY for packages not in nixpkgs or severely outdated.
# Prefer nixpkgs for everything - only use homebrew when absolutely necessary.

_:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false; # Don't download 45MB index on every rebuild (fast)
      cleanup = "none"; # Don't remove manually installed packages
      upgrade = true; # Upgrade packages based on cached index
      # To get new versions: run `brew update` then `darwin-rebuild switch`
    };
    taps = [
      # "homebrew/cask"   # Example: additional taps
    ];
    brews = [
      # CLI tools (only if not available in nixpkgs)
      # ccusage moved to nix - see modules/home-manager/ai-cli/ai-tools.nix
    ];
    casks = [
      # GUI applications (only if not available in nixpkgs)
      "shortwave" # AI-powered email client
      "claude" # Anthropic Claude desktop app (not in nixpkgs for Darwin)
      # NOTE: ChatGPT, Cursor, Antigravity are in nixpkgs - see home.packages
    ];

    # Mac App Store apps (requires signed into App Store)
    # Find app IDs: mas search <name> or https://github.com/mas-cli/mas
    # Format: "App Name" = app_id;
    masApps = {
      "Toggl Track" = 1291898086; # Time tracking
      "Monarch Money Tweaks" = 6753774259; # Personal finance enhancements
      # NOTE: GoPro Quik (561350520) removed - no longer needed
    };
  };
}
