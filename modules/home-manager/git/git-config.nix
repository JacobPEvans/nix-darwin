# Git Configuration
#
# Fully Nix-managed git config (~/.config/git/config)
# Security policy: All commits and tags must be GPG signed
#
# This file returns a programs.git attribute set to be merged in common.nix

{ ... }:

let
  userConfig = import ../../../lib/user-config.nix;
  gitAliases = import ./git-aliases.nix;
in
{
  programs.git = {
    enable = true;

    # ========================================================================
    # GPG Signing
    # ========================================================================
    # NOTE: Key ID is a public identifier, not the private key (safe to commit)
    signing = {
      key = userConfig.gpg.signingKey;
      signByDefault = true;   # Enforced by security policy
    };

    # ========================================================================
    # Git Settings
    # ========================================================================
    settings = {
      # User identity
      user = {
        name = userConfig.user.fullName;
        email = userConfig.user.email;
      };

      # Core settings
      core = {
        editor = userConfig.git.editor;
        autocrlf = "input";           # LF on commit, unchanged on checkout (Unix-style)
        whitespace = "trailing-space,space-before-tab";
      };

      # Repository initialization
      init.defaultBranch = userConfig.git.defaultBranch;

      # Pull behavior - rebase keeps history cleaner than merge commits
      pull.rebase = true;

      # Push behavior
      push = {
        autoSetupRemote = true;       # Auto-track remote branches
        default = "current";          # Push current branch to same-named remote
      };

      # Fetch behavior
      fetch = {
        prune = true;                 # Auto-remove deleted remote branches
        pruneTags = true;             # Auto-remove deleted remote tags
      };

      # Merge & diff improvements
      merge = {
        conflictstyle = "diff3";      # Show original in conflicts
        ff = "only";                  # Only fast-forward merges
      };
      diff = {
        algorithm = "histogram";      # Better diff algorithm
        colorMoved = "default";       # Highlight moved lines
        mnemonicPrefix = true;        # Use i/w/c/o instead of a/b
      };

      # Rerere - remember merge conflict resolutions
      rerere = {
        enabled = true;
        autoupdate = true;
      };

      # Sign all tags (security policy)
      tag.gpgSign = true;

      # Helpful features
      help.autocorrect = 10;          # Auto-correct typos after 1 second
      status.showStash = true;        # Show stash count in git status
      log.date = "iso";               # Use ISO date format
      branch.sort = "-committerdate"; # Sort branches by recent commits

      # Git aliases - see git-aliases.nix
      alias = gitAliases;
    };
  };
}
