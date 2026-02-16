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
{
  config,
  lib,
  pkgs,
  ...
}:

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
        cleanupMarketplaceDirectories =
          lib.hm.dag.entryBefore [ "linkGeneration" ]
            "$DRY_RUN_CMD ${./scripts/cleanup-marketplace-directories.sh} ${lib.escapeShellArg config.home.homeDirectory} ${lib.concatStringsSep " " (map lib.escapeShellArg marketplacePaths)}";

        # Cache integrity verification and cleanup
        # Addresses upstream bug where stale cache prevents updated plugins from loading
        # GitHub issue: anthropics/claude-code#17361
        # MUST run after linkGeneration to ensure symlinks are created first
        verifyCacheIntegrity =
          lib.hm.dag.entryAfter [ "linkGeneration" ]
            "$DRY_RUN_CMD ${./scripts/verify-cache-integrity.sh} ${lib.escapeShellArg config.home.homeDirectory} ${lib.escapeShellArg "${pkgs.coreutils}/bin"} ${lib.concatStringsSep " " (map lib.escapeShellArg marketplacePaths)}";

        # Post-activation script to show diffs for manual review
        reportMarketplaceDiffs =
          lib.hm.dag.entryAfter [ "linkGeneration" ]
            "$DRY_RUN_CMD ${./scripts/report-marketplace-diffs.sh} ${lib.escapeShellArg "${pkgs.coreutils}/bin"} ${lib.concatStringsSep " " (map lib.escapeShellArg marketplacePaths)}";
      };
    };
  };
}
