# Git Hooks (Auto-installed via templates)
#
# These hooks are installed automatically on new git clones via init.templateDir.
# They delegate to pre-commit framework if .pre-commit-config.yaml exists.
#
# Layer 1 of 3-layer defense:
#   1. Auto-install hooks (this) - fast local feedback
#   2. AI deny list - blocks --no-verify bypass attempts
#   3. GitHub branch protection - server-side guarantee
#
# For existing repos, run: git config init.templateDir ~/.git-templates && pre-commit install

{ config, pkgs, ... }:

let
  # Pre-commit hook: runs on every commit
  preCommitHook = pkgs.writeShellScript "pre-commit" ''
    # Skip if no pre-commit config
    if [ ! -f .pre-commit-config.yaml ]; then
      exit 0
    fi

    # Check for pre-commit framework
    # NOTE: Warning only (not blocking) - pre-commit may not be installed in all environments
    # Layer 2 (AI deny list) and Layer 3 (GitHub branch protection) provide enforcement
    if ! command -v pre-commit &> /dev/null; then
      echo "Warning: .pre-commit-config.yaml exists but pre-commit is not installed" >&2
      echo "Add pre-commit to your Nix configuration and rebuild" >&2
      exit 0
    fi

    # Run pre-commit hooks
    exec pre-commit run --hook-stage commit
  '';

  # Pre-push hook: runs before push (secondary gate)
  prePushHook = pkgs.writeShellScript "pre-push" ''
    # Skip if no pre-commit config
    if [ ! -f .pre-commit-config.yaml ]; then
      exit 0
    fi

    # Check for pre-commit framework
    # NOTE: Warning only - don't block push, but inform user checks were skipped
    if ! command -v pre-commit &> /dev/null; then
      echo "Warning: pre-commit not found, skipping pre-push checks." >&2
      exit 0
    fi

    # Run all pre-commit hooks on all files
    exec pre-commit run --all-files --hook-stage push
  '';
in
# Return file definitions directly (merged into home.file in common.nix)
{
  ".git-templates/hooks/pre-commit" = {
    source = preCommitHook;
    executable = true;
  };
  ".git-templates/hooks/pre-push" = {
    source = prePushHook;
    executable = true;
  };
}
