# Claude Code Plugin Management
#
# Symlinks Nix-managed plugin directories from flake inputs.
# Runtime plugins are unaffected - they live in separate directories.
#
# Automatic cleanup: When a marketplace directory exists but should be a symlink,
# it's automatically removed (with diff reporting). Only one backup is kept.
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
        # Log format: [HH:MM:SS] [LOG_LEVEL] message
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
              echo "[$(date '+%H:%M:%S')] [INFO] Cleaned up marketplace directory: ${path}" >&2
              echo "[$(date '+%H:%M:%S')] [INFO]   Backup saved to: $BACKUP" >&2
              echo "[$(date '+%H:%M:%S')] [INFO]   After activation completes, a diff will be shown" >&2
            fi
          '') marketplacePaths}
        '';

        # Post-activation script to show diffs for manual review
        # Log format: [HH:MM:SS] [LOG_LEVEL] message
        reportMarketplaceDiffs = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          # Show diffs between backed-up directories and new Nix-managed symlinks
          # Backups are kept for manual review and deletion
          ${lib.concatMapStringsSep "\n" (path: ''
            BACKUP="${path}.backup"
            if [ -d "$BACKUP" ]; then
              echo "" >&2
              echo "[$(date '+%H:%M:%S')] [INFO] Marketplace update: ${path}" >&2

              if [ -L "${path}" ]; then
                NEW_TARGET=$(readlink "${path}")
                echo "[$(date '+%H:%M:%S')] [INFO]   Old: Real directory (runtime install)" >&2
                echo "[$(date '+%H:%M:%S')] [INFO]   New: Symlink -> $NEW_TARGET (Nix-managed)" >&2
                echo "[$(date '+%H:%M:%S')] [INFO]   Comparing directories (showing first 20 differences):" >&2

                # Show directory structure comparison
                diff -r "$BACKUP" "${path}" 2>&1 | head -20 || true

                echo "[$(date '+%H:%M:%S')] [INFO]   Full comparison available at: $BACKUP" >&2
                echo "[$(date '+%H:%M:%S')] [INFO]   Review and manually delete backup when satisfied." >&2
              fi
            fi
          '') marketplacePaths}
        '';
      };
    };
  };
}
