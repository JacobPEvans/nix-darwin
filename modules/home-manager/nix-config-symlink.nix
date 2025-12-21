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

    # CRITICAL: Never use "exit" in activation scripts - it kills the ENTIRE activation!
    # Use if/elif/else control flow instead.

    if [ ! -d "$NIX_CONFIG_TARGET" ]; then
      # Target doesn't exist yet, skip (will be created by user's worktree setup)
      echo "WARNING: $NIX_CONFIG_TARGET does not exist yet."
      echo "After initializing your worktrees, run: sudo darwin-rebuild switch"
    elif [ -L "$NIX_CONFIG_PATH" ] && [ "$(readlink "$NIX_CONFIG_PATH")" = "$NIX_CONFIG_TARGET" ]; then
      # Already points to the right place, nothing to do
      true
    else
      # Need to create or fix the symlink
      if [ -e "$NIX_CONFIG_PATH" ] || [ -L "$NIX_CONFIG_PATH" ]; then
        # Backup existing file/symlink before replacing
        echo "Backing up existing ~/.config/nix"
        mv "$NIX_CONFIG_PATH" "$NIX_CONFIG_PATH.backup.$(date +%Y%m%d_%H%M%S)"
      fi
      # Create symlink
      ln -s "$NIX_CONFIG_TARGET" "$NIX_CONFIG_PATH"
      echo "Created symlink: $NIX_CONFIG_PATH -> $NIX_CONFIG_TARGET"
    fi
  '';
}
