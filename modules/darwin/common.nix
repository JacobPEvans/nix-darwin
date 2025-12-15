{ pkgs, lib, ... }:

let
  userConfig = import ../../lib/user-config.nix;

  # Universal packages (pre-commit, linters) shared across all systems
  commonPackages = import ../common/packages.nix { inherit pkgs; };
in
{
  imports = [
    ./apps
    ./dock
    ./finder.nix
    ./keyboard.nix
    ./security.nix
    ./terminal.nix
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
    inherit (userConfig.user) name;
    home = userConfig.user.homeDir;
  };

  # Required for nix-darwin with Determinate Nix
  system.primaryUser = userConfig.user.name;

  # System packages from nixpkgs
  # All packages should come from nixpkgs - homebrew is fallback only
  environment.systemPackages =
    commonPackages
    ++ (with pkgs; [
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
      bat # Better cat with syntax highlighting
      delta # Better git diff viewer with syntax highlighting
      eza # Modern ls replacement with git integration
      fd # Faster, user-friendly find alternative
      fzf # Fuzzy finder for interactive selection
      htop # Interactive process viewer (better top)
      jq # JSON parsing for config files and API responses
      yq # YAML parsing (like jq but for YAML/XML/TOML)
      ncdu # NCurses disk usage analyzer
      ripgrep # Fast grep alternative (rg)
      tldr # Simplified, community-driven man pages
      tree # Directory tree visualization

      # ========================================================================
      # Development tools
      # ========================================================================
      claude-code # Anthropic's agentic coding CLI
      claude-monitor # Real-time Claude Code usage monitor
      gemini-cli # Google's Gemini CLI
      gh # GitHub CLI
      mas # Mac App Store CLI (search: mas search <app>, install: mas install <id>)
      nodejs # Node.js LTS (nixpkgs default tracks current LTS)
      # NOTE: ollama not included - nixpkgs build fails; using manual Ollama.app install
      # See hosts/macbook-m4/home.nix for models symlink to /Volumes/Ollama

      # ========================================================================
      # GUI applications
      # ========================================================================
      bitwarden-desktop # Password manager desktop app
      obsidian # Knowledge base / note-taking (Markdown)
      # OrbStack: Docker & Linux VM manager (lightweight alternative to Docker Desktop)
      # Provides: docker, docker-compose, docker-buildx, kubectl, orb, orbctl
      # CLIs installed to /usr/local/bin via OrbStack's helper tool
      # Docker socket: /var/run/docker.sock (managed by programs.orbstack module)
      orbstack
      raycast # Productivity launcher (replaces Spotlight)
      vscode # Visual Studio Code editor
      zoom-us # Video conferencing
    ]);

  # Homebrew as FALLBACK ONLY for packages not in nixpkgs or severely outdated
  # Prefer nixpkgs for everything - only use homebrew when absolutely necessary
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
      "ccusage" # Claude Code usage analyzer (not in nixpkgs)
    ];
    casks = [
      # GUI applications (only if not available in nixpkgs)
    ];

    # Mac App Store apps (requires signed into App Store)
    # Find app IDs: mas search <name> or https://github.com/mas-cli/mas
    # Format: "App Name" = app_id;
    masApps = {
      # "Xcode" = 497799835;
      # "1Password" = 1333542190;
    };
  };

  # ==========================================================================
  # Programs Configuration
  # ==========================================================================
  programs = {
    zsh.enable = true;
    raycast.enable = true; # Declarative Raycast preferences
    terminal.enable = true; # Terminal.app window size (180x80 for Basic profile)
  };

  # ==========================================================================
  # Nix Configuration (Determinate Nix compatibility)
  # ==========================================================================
  # Disable nix-darwin's Nix management - Determinate Nix manages daemon and nix itself
  # Workaround: home-manager's darwin module accesses nix.package even when enable=false
  # Using mkForce bypasses the throw in nix-darwin's managedDefault
  # See: https://github.com/nix-community/home-manager/issues/4026
  nix = {
    enable = false;
    package = lib.mkForce pkgs.nix;
  };

  # Disable documentation to suppress builtins.toFile warnings
  documentation.enable = false;

  # macOS system version (required for nix-darwin)
  system.stateVersion = 5;
}
