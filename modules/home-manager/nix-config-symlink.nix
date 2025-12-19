# Nix Config Symlink Module
#
# Creates a read-only symlink at ~/.config/nix pointing to the production
# nix config from the main branch (fetched as a flake input).
#
# This prevents accidental edits to the production config:
# - ~/.config/nix -> read-only (nix store)
# - ~/git/nix-config -> development worktrees (writable)
#
# The symlink points to the nix store, so any edits will fail with
# "Read-only file system". This forces all development work to happen
# in the proper git worktree workflow.
{
  lib,
  nix-config-main,
  ...
}:

{
  # Create symlink: ~/.config/nix -> /nix/store/.../nix-config-main
  home.file.".config/nix".source = nix-config-main;

  # Activation script to warn if existing ~/.config/nix is not a symlink
  home.activation.checkNixConfigSymlink = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -e "$HOME/.config/nix" ] && [ ! -L "$HOME/.config/nix" ]; then
      echo ""
      echo "WARNING: ~/.config/nix exists and is not a symlink!"
      echo "This module will replace it with a symlink to the nix store."
      echo ""
      echo "If you have uncommitted changes in ~/.config/nix:"
      echo "  1. Move them to ~/git/nix-config worktree"
      echo "  2. Remove ~/.config/nix: rm -rf ~/.config/nix"
      echo "  3. Re-run darwin-rebuild switch"
      echo ""
      echo "Backing up to ~/.config/nix.backup.\$(date +%Y%m%d_%H%M%S)"
      mv "$HOME/.config/nix" "$HOME/.config/nix.backup.\$(date +%Y%m%d_%H%M%S)"
    fi
  '';
}
