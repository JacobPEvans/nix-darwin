# User-Specific Configuration Variables
#
# Centralizes user-specific values that may vary between machines or users.
# Import this file wherever user-specific values are needed.
#
# These values are safe to commit to git:
# - GPG key IDs are public identifiers (not private keys)
# - Email addresses are often public (GitHub noreply recommended)
# - Usernames are public information

let
  # Define username once, derive everything else from it
  username = "jevans";

  # Home directory path (derived from username for macOS)
  # macOS-specific - this configuration is Darwin-only
  # Use this for paths in darwin modules where config.home.homeDirectory
  # is not available
  homeDir = "/Users/${username}";
in
{
  # ==========================================================================
  # User Identity
  # ==========================================================================
  user = {
    # System username (matches macOS account)
    name = username;

    # Expose homeDir for modules that need it
    inherit homeDir;

    # Full name for git commits and other identity purposes
    fullName = "JacobPEvans";

    # Primary email (GitHub noreply for privacy)
    email = "20714140+JacobPEvans@users.noreply.github.com";
  };

  # ==========================================================================
  # Host Configuration
  # ==========================================================================
  host = {
    # Network hostname (used for networking.hostName, ComputerName, etc.)
    name = "jevans-mbp";
  };

  # ==========================================================================
  # GPG Configuration
  # ==========================================================================
  # NOTE: These are PUBLIC key identifiers, NOT private keys.
  # Safe to commit - GitHub displays these on every signed commit.
  gpg = {
    # Primary signing key ID (public identifier)
    signingKey = "31652F22BF6AC286";
  };

  # ==========================================================================
  # Git Configuration
  # ==========================================================================
  git = {
    # Default editor for commit messages
    editor = "vim";

    # Default branch name for new repositories
    defaultBranch = "main";
  };

  # ==========================================================================
  # AI Assistant Configuration
  # ==========================================================================
  # NOTE: Most ai-assistant-instructions content comes from Nix store (flake input).
  # The local repo path below is ONLY used by autoClaude for autonomous commits.
  #
  # Repository uses git worktrees:
  #   - Main branch: ~/git/ai-assistant-instructions/main/
  #   - Feature branches: ~/git/ai-assistant-instructions/<branch-name>/
  # Clone with worktree setup:
  #   git clone --bare https://github.com/JacobPEvans/ai-assistant-instructions.git ~/git/ai-assistant-instructions
  #   cd ~/git/ai-assistant-instructions && git worktree add main main
  ai = {
    # Local repo path - ONLY for autoClaude (needs writable git for commits)
    # All other content (permissions, commands, instruction files) comes from flake input
    instructionsRepo = "${homeDir}/git/ai-assistant-instructions/main";

    # Claude Code settings JSON Schema URL (official schema store)
    # Used by: settings.json $schema, pre-commit hooks, CI validation, activation hooks
    # Single source of truth - reference this everywhere
    claudeSchemaUrl = "https://json.schemastore.org/claude-code-settings.json";
  };

  # ==========================================================================
  # Nix/NixOS Configuration
  # ==========================================================================
  nix = {
    # Home-manager stateVersion - single source of truth
    # NixOS 25.05 "Warbler" (released May 2025)
    # Update this when upgrading to a new NixOS stable release
    # Reference: https://nixos.org/blog/announcements/
    homeManagerStateVersion = "25.05";

    # Automatic garbage collection schedule
    # Centralized configuration for nix-darwin's gc.interval and gc.options
    gc = {
      weekday = 0; # Sunday (0 = Sunday, 1 = Monday, ... 6 = Saturday)
      hour = 3; # 3 AM
      minute = 0;
      retention = "30d"; # Keep generations from last 30 days
    };
  };
}
