# Nix Config Symlink Module
#
# Creates a symlink at ~/.config/nix pointing to the main branch worktree.
# This enables ~/git/nix-config/main to be the single source of truth for
# production configuration.
#
# Architecture:
# - ~/.config/nix -> ~/git/nix-config/main (direct filesystem symlink)
# - ~/git/nix-config/main -> main branch worktree (always synced via git pull)
# - ~/git/nix-config/<feature> -> development worktrees (for feature work)
#
# When you run `darwin-rebuild switch --flake ~/.config/nix`, it uses the
# production config from main. When you run it from a feature worktree,
# you test against that worktree's changes.
#
# Benefits:
# - No flake input locking needed
# - Always reflects latest main after `git pull`
# - Simpler architecture
# - Prevents accidental edits to main (it's just a worktree, treat it as read-only)
{
  config,
  lib,
  ...
}:

{
  # Create symlink via activation script
  # This approach works across all home-manager versions and directly creates a filesystem symlink
  home.activation.createNixConfigSymlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Get paths
    NIX_CONFIG_PATH="$HOME/.config/nix"
    NIX_CONFIG_TARGET="$HOME/git/nix-config/main"

    # If target doesn't exist, skip (will be created by user's worktree setup)
    if [ ! -d "$NIX_CONFIG_TARGET" ]; then
      echo "WARNING: $NIX_CONFIG_TARGET does not exist yet."
      echo "After initializing your worktrees, run: sudo darwin-rebuild switch"
      exit 0
    fi

    # Check if ~/.config/nix exists and is not pointing to the right place
    if [ -e "$NIX_CONFIG_PATH" ] || [ -L "$NIX_CONFIG_PATH" ]; then
      # If it's a symlink, check if it points to the right place
      if [ -L "$NIX_CONFIG_PATH" ]; then
        CURRENT_TARGET=$(readlink "$NIX_CONFIG_PATH")
        if [ "$CURRENT_TARGET" = "$NIX_CONFIG_TARGET" ]; then
          # Already points to the right place, nothing to do
          exit 0
        fi
      fi

      # Either it's not a symlink, or it points to the wrong place
      echo "Backing up existing ~/.config/nix"
      mv "$NIX_CONFIG_PATH" "$NIX_CONFIG_PATH.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Create symlink
    ln -s "$NIX_CONFIG_TARGET" "$NIX_CONFIG_PATH"
    echo "Created symlink: $NIX_CONFIG_PATH -> $NIX_CONFIG_TARGET"
  '';
}
