# Claude Code Plugin Management
#
# Symlinks Nix-managed plugin directories from flake inputs.
# Runtime plugins are unaffected - they live in separate directories.
#
# Automatic cleanup: When a marketplace directory exists but should be a symlink,
# it's automatically removed (with diff reporting). Only one backup is kept.
#
# ACTIVATION SCRIPT ORDERING (using home-manager DAG):
#
# 1. cleanupMarketplaceDirectories (entryBefore linkGeneration)
#    - Runs BEFORE home-manager creates symlinks
#    - Moves conflicting directories to .backup
#    - Required to prevent "cannot overwrite directory" errors
#
# 2. linkGeneration (home-manager built-in)
#    - Creates all symlinks defined in home.file
#
# 3. reportMarketplaceDiffs (entryAfter linkGeneration)
#    - Runs AFTER symlinks are created
#    - Shows diffs between backup and new Nix-managed content
#    - Helps users verify marketplace transitions
#
# Do NOT change this ordering without understanding the dependencies.
{ config, lib, ... }:

let
  cfg = config.programs.claude;

  # Extract marketplace name from the identifier
  # e.g., "anthropics/claude-plugins-official" -> "claude-plugins-official"
  # Implementation matches lib/claude-registry.nix for consistency
  getMarketplaceName = name: lib.last (lib.splitString "/" name);

  # Create symlink entries for Nix-managed marketplaces
  nixManagedMarketplaces = lib.filterAttrs (_: m: m.flakeInput != null) cfg.plugins.marketplaces;

  marketplaceSymlinks = lib.mapAttrs' (
    name: marketplace:
    lib.nameValuePair ".claude/plugins/marketplaces/${getMarketplaceName name}" {
      source = marketplace.flakeInput;
      force = true;
    }
  ) nixManagedMarketplaces;

  # Generate list of marketplace paths that should be symlinks
  marketplacePaths = lib.mapAttrsToList (
    name: _: "${config.home.homeDirectory}/.claude/plugins/marketplaces/${getMarketplaceName name}"
  ) nixManagedMarketplaces;

in
{
  config = lib.mkIf cfg.enable {
    home = {
      file = marketplaceSymlinks;

      activation = {
        # Activation script to clean up conflicting marketplace directories
        # MUST run before linkGeneration to prevent "cannot overwrite directory" errors
        # Log format: YYYY-MM-DD HH:MM:SS [LOG_LEVEL] message
        cleanupMarketplaceDirectories = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
          # Clean up marketplace directories that conflict with Nix-managed symlinks
          # This handles the case where runtime plugin installs created real directories
          # that now prevent Nix from creating symlinks
          ${lib.concatMapStringsSep "\n" (path: ''
            if [ -d "${path}" ] && [ ! -L "${path}" ]; then
              BACKUP="${path}.backup"

              # Remove old backup if it exists (only keep one)
              if [ -e "$BACKUP" ]; then
                rm -rf "$BACKUP"
              fi

              # Move directory to backup
              mv "${path}" "$BACKUP"
              echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Cleaned up marketplace directory: ${path}" >&2
              echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Backup saved to: $BACKUP" >&2
              echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   After activation completes, a diff will be shown" >&2
            fi
          '') marketplacePaths}
        '';

        # Post-activation script to show diffs for manual review
        # Log format: YYYY-MM-DD HH:MM:SS [LOG_LEVEL] message
        reportMarketplaceDiffs = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          # Show diffs between backed-up directories and new Nix-managed symlinks
          # Backups are kept for manual review and deletion
          ${lib.concatMapStringsSep "\n" (path: ''
            BACKUP="${path}.backup"
            if [ -d "$BACKUP" ]; then
              echo "" >&2
              echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Marketplace update: ${path}" >&2

              if [ -L "${path}" ]; then
                NEW_TARGET=$(readlink "${path}")
                echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Old: Real directory (runtime install)" >&2
                echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   New: Symlink -> $NEW_TARGET (Nix-managed)" >&2

                # Verify symlink target exists before diffing
                if [ ! -e "$NEW_TARGET" ]; then
                  echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN]   Symlink target does not exist: $NEW_TARGET" >&2
                  echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN]   Cannot compare directories" >&2
                elif [ ! -d "$NEW_TARGET" ]; then
                  echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN]   Symlink target is not a directory: $NEW_TARGET" >&2
                  echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN]   Cannot compare directories" >&2
                else
                  echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Comparing directories (showing first 20 differences):"

                  # Show directory structure comparison
                  # diff exit codes: 0=identical, 1=different, 2+=error
                  # NOTE: || true prevents set -e/pipefail from aborting the
                  # activation script when diff finds differences (exit 1)
                  diff_output=$(diff -r "$BACKUP" "${path}" 2>&1 | head -20 || true)
                  diff_exit=''${PIPESTATUS[0]}

                  if [ $diff_exit -eq 0 ]; then
                    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Directories are identical"
                  elif [ $diff_exit -eq 1 ]; then
                    echo "$diff_output"
                  else
                    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR]  diff command failed (exit code: $diff_exit). Output follows:" >&2
                    echo "$diff_output" >&2
                  fi
                fi

                echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Full comparison available at: $BACKUP" >&2
                echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]   Review and manually delete backup when satisfied." >&2
              fi
            fi
          '') marketplacePaths}
        '';
      };
    };
  };
}
