# Homebrew Configuration
#
# Homebrew is a FALLBACK ONLY for packages not in nixpkgs or severely outdated.
# Prefer nixpkgs for everything - only use homebrew when absolutely necessary.
#
# NOTE: nix-darwin does NOT support version pinning for individual homebrew packages.
# Packages will be upgraded to latest available when `upgrade = true` and you run
# `darwin-rebuild switch`. To prevent upgrades, set `upgrade = false` or pin the
# package version manually via `brew pin <package>`.

_:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false; # Don't download 45MB index on every rebuild (fast)
      cleanup = "none"; # Don't remove manually installed packages
      upgrade = true; # Upgrade packages to latest available
    };
    taps = [
      # "homebrew/cask"   # Example: additional taps
    ];
    brews = [
      # CLI tools (only if not available in nixpkgs)
      "ccusage" # Claude Code usage analyzer - not in nixpkgs
      "block-goose-cli" # Block Goose AI agent (verified via: brew search goose) - conflicts with nixpkgs 'goose'
      "claude-code" # Anthropic Claude Code CLI
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
