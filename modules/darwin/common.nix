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
    # ========================================================================
    # Core CLI tools
    # ========================================================================
    git
    gnupg
    vim

    # ========================================================================
    # Modern CLI tools (popular alternatives, also useful for AI CLI agents)
    # These enhance productivity for both humans and AI assistants
    # ========================================================================
    bat             # Better cat with syntax highlighting
    delta           # Better git diff viewer with syntax highlighting
    eza             # Modern ls replacement with git integration
    fd              # Faster, user-friendly find alternative
    fzf             # Fuzzy finder for interactive selection
    htop            # Interactive process viewer (better top)
    jq              # JSON parsing for config files and API responses
    ncdu            # NCurses disk usage analyzer
    ripgrep         # Fast grep alternative (rg)
    tldr            # Simplified, community-driven man pages
    tree            # Directory tree visualization

    # ========================================================================
    # Development tools
    # ========================================================================
    gemini-cli      # Google's Gemini CLI
    gh              # GitHub CLI
    nodejs_latest   # Node.js runtime

    # ========================================================================
    # GUI applications
    # ========================================================================
    raycast         # Productivity launcher (replaces Spotlight)
    vscode          # Visual Studio Code editor
  ];

  # Homebrew as FALLBACK ONLY for packages not in nixpkgs or severely outdated
  # Prefer nixpkgs for everything - only use homebrew when absolutely necessary
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;   # Don't download 45MB index on every rebuild (fast)
      cleanup = "none";     # Don't remove manually installed packages
      upgrade = true;       # Upgrade packages based on cached index
      # To get new versions: run `brew update` then `darwin-rebuild switch`
    };
    taps = [
      # "homebrew/cask"   # Example: additional taps
    ];
    brews = [
      # CLI tools (only if not available in nixpkgs)
    ];
    casks = [
      # GUI applications (only if not available in nixpkgs)

      # claude-code: Rapidly-evolving developer tool
      # - Nixpkgs version lags behind releases
      # - Can't auto-update from read-only nix store
      # - Manual upgrade: brew upgrade --cask claude-code
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

