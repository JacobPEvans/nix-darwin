{ pkgs, ... }:

let
  userConfig = import ../../lib/user-config.nix;

  # Universal packages (pre-commit, linters) shared across all systems
  commonPackages = import ../common/packages.nix { inherit pkgs; };
in
{
  imports = [
    ./dock.nix
    ./finder.nix
    ./keyboard.nix
    ./trackpad.nix
    ./system-ui.nix
  ];

  # ==========================================================================
  # Nixpkgs Configuration
  # ==========================================================================
  nixpkgs.config.allowUnfree = true;

  # ==========================================================================
  # User Configuration
  # ==========================================================================
  users.users.${userConfig.user.name} = {
    name = userConfig.user.name;
    home = "/Users/${userConfig.user.name}";
  };

  # Required for nix-darwin with Determinate Nix
  system.primaryUser = userConfig.user.name;

  # System packages from nixpkgs
  # All packages should come from nixpkgs - homebrew is fallback only
  environment.systemPackages = commonPackages ++ (with pkgs; [
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
    mas             # Mac App Store CLI (search: mas search <app>, install: mas install <id>)
    nodejs_latest   # Node.js runtime
    # NOTE: ollama not included - nixpkgs build fails; using manual Ollama.app install
    # See hosts/macbook-m4/home.nix for models symlink to /Volumes/Ollama

    # ========================================================================
    # GUI applications
    # ========================================================================
    obsidian        # Knowledge base / note-taking (Markdown)
    raycast         # Productivity launcher (replaces Spotlight)
    vscode          # Visual Studio Code editor
    zoom-us         # Video conferencing
  ]);

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

    # Mac App Store apps (requires signed into App Store)
    # Find app IDs: mas search <name> or https://github.com/mas-cli/mas
    # Format: "App Name" = app_id;
    masApps = {
      # "Xcode" = 497799835;
      # "1Password" = 1333542190;
    };
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

