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

      # Block Goose AI agent (https://github.com/block/goose)
      # - Using homebrew as nixpkgs version was >30 days old at time of addition; homebrew actively maintained
      # - Named 'block-goose-cli' to avoid conflict with nixpkgs 'goose' (database migration tool)
      "block-goose-cli"
    ];
    casks = [
      # GUI applications (only if not available in nixpkgs)
      #
      # TCC NOTE: Homebrew casks install directly to /Applications/ (real copies,
      # not symlinks to /nix/store), so macOS TCC permissions (camera, mic, screen
      # recording) persist across darwin-rebuild. This is different from nixpkgs
      # apps which require copyApps workaround in home-manager.
      "shortwave" # AI-powered email client
      "claude" # Anthropic Claude desktop app (not in nixpkgs for Darwin)
      "claude-code" # Anthropic Claude Code CLI (version 2.1.3)
      "wispr-flow" # AI-powered voice dictation app
      # NOTE: ChatGPT, Cursor, Antigravity are in nixpkgs - see home.packages
    ];

    # Mac App Store apps (requires signed into App Store)
    # Find app IDs: mas search <name> or https://github.com/mas-cli/mas
    # Format: "App Name" = app_id;
    masApps = {
      "Toggl Track" = 1291898086; # Time tracking
      "Monarch Money Tweaks" = 6753774259; # Personal finance enhancements
      # NOTE: GoPro Quik (561350520) removed - no longer needed

      # Microsoft 365 bundle (https://apps.apple.com/us/app-bundle/microsoft-365/id1450038993)
      # NOTE: First-time install requires `sudo mas install <id>` due to TTY/sudo constraints
      # Individual apps from the bundle - replaces any non-App Store versions
      "Microsoft Word" = 462054704;
      "Microsoft Excel" = 462058435;
      "Microsoft PowerPoint" = 462062816;
      "Microsoft Outlook" = 985367838;
      "Microsoft OneNote" = 784801555;
      "OneDrive" = 823766827;
    };
  };
}
