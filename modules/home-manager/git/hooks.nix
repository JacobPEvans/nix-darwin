# Git Hooks (Global via core.hooksPath)
#
# These hooks apply to ALL git repos via core.hooksPath (set in common.nix).
# They delegate to pre-commit framework if .pre-commit-config.yaml exists.
#
# Layer 1 of 3-layer defense:
#   1. Global hooks (this) - fast local feedback on ALL repos
#   2. AI deny list - blocks --no-verify bypass attempts
#   3. GitHub branch protection - server-side guarantee

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

    # Run pre-commit hooks only on files changed in the push (not all files).
    # Using --from-ref/--to-ref prevents heavy hooks (e.g. terragrunt-plan)
    # from running when only unrelated files (e.g. YAML) are pushed.
    # Reads the ref pairs from stdin as per the git pre-push hook protocol.
    exit_code=0
    while read local_ref local_sha remote_ref remote_sha; do
      if [ "$remote_sha" = "0000000000000000000000000000000000000000" ]; then
        # New branch: compare against the empty tree
        from=$(git hash-object -t tree /dev/null)
      else
        from="$remote_sha"
      fi
      to="$local_sha"
      pre-commit run --from-ref "$from" --to-ref "$to" --hook-stage push || exit_code=$?
    done
    exit $exit_code
  '';
  # Return file definitions directly (merged into home.file in common.nix)
in
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
