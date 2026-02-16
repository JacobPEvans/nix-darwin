# Homebrew Configuration
#
# Homebrew is a FALLBACK ONLY for packages not in nixpkgs or severely outdated.
# Prefer nixpkgs for everything - only use homebrew when absolutely necessary.
#
# == Update Philosophy ==
#
# Homebrew has NO native background auto-update mechanism. The "passive auto-update"
# is just a convenience feature that runs `brew update` when you invoke certain
# commands (if >5 minutes have passed). There is no background daemon.
#
# Our configuration:
#   - onActivation.autoUpdate = false  → Keeps rebuilds fast (no 45MB index download)
#   - onActivation.upgrade = true      → Packages updated when you run darwin-rebuild
#   - Passive auto-update: Enabled     → >5 minutes trigger on command invocation
#
# == How Packages Get Updated ==
#
# 1. AUTOMATIC: Run `darwin-rebuild switch` - upgrades all packages to latest
# 2. MANUAL: Run `brew update && brew upgrade` for immediate updates
# 3. RENOVATE: Cannot track homebrew versions (no version info in this config)
#
# == Why Renovate Can't Help ==
#
# nix-darwin homebrew config contains only package names, not versions.
# Homebrew lacks declarative version pinning within configuration files.
# Renovate's homebrew manager only works with Ruby Formula files.
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
      # Don't download 45MB index on every rebuild - keeps rebuilds fast and deterministic.
      # Homebrew's passive auto-update still works (triggers on command invocation after >5 minutes).
      autoUpdate = false;
      cleanup = "none"; # Don't remove manually installed packages
      # Upgrade packages to latest available when darwin-rebuild switch runs.
      # This is the primary mechanism for keeping homebrew packages current.
      upgrade = true;
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
      "obsidian" # Knowledge base / note-taking - brew for faster beta updates
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
