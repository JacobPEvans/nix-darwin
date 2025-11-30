# User-Specific Configuration Variables
#
# Centralizes user-specific values that may vary between machines or users.
# Import this file wherever user-specific values are needed.
#
# These values are safe to commit to git:
# - GPG key IDs are public identifiers (not private keys)
# - Email addresses are often public (GitHub noreply recommended)
# - Usernames are public information

{
  # ==========================================================================
  # User Identity
  # ==========================================================================
  user = {
    # System username (matches macOS account)
    name = "jevans";

    # NOTE: Home directory path removed - use config.home.homeDirectory instead
    # This avoids duplication with darwin/configuration.nix

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
}
