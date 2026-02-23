# Orphan Cleanup Module
#
# Two-phase cleanup for Nix-managed directories:
#
# Phase 1 (BEFORE linkGeneration):
# - Removes directory symlinks that conflict with individual file symlinks
# - This handles the case where a previous generation symlinked the entire
#   directory to the nix store, but the new generation creates individual files
#
# Phase 2 (AFTER linkGeneration):
# - Removes broken symlinks (targets that don't exist)
# - This handles commands/agents/skills removed from the Nix configuration
#
# Phase 3 (AFTER linkGeneration):
# - Verifies plugin cache integrity when marketplace symlinks change
#
{ config, lib, ... }:

let
  cfg = config.programs.claude;
  homeDir = config.home.homeDirectory;

  # Log helper function with timestamp and level
  # Format: YYYY-MM-DD HH:MM:SS [LOG_LEVEL] message
  logHelper = ''
    log_info() {
      echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >&2
    }
    log_warn() {
      echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $1" >&2
    }
  '';

  # Component directories that are managed as individual files (not directory symlinks)
  componentDirs = [
    "${homeDir}/.claude/commands"
    "${homeDir}/.claude/agents"
    "${homeDir}/.claude/skills"
    "${homeDir}/.gemini/commands"
  ];

  # Pre-cleanup: Remove directory symlinks that point to nix store
  # This is needed when switching from directory symlinks to individual file symlinks
  preCleanupDir = dir: ''
    if [ -L "${dir}" ]; then
      TARGET=$(readlink "${dir}")
      if [[ "$TARGET" == /nix/store/* ]]; then
        if $DRY_RUN_CMD rm "${dir}"; then
          log_info "Removed conflicting directory symlink: ${dir}"
          log_info "  (was: $TARGET)"
        else
          log_warn "Failed to remove directory symlink: ${dir}"
        fi
      fi
    fi
  '';

  # Post-cleanup: Remove broken symlinks (targets that don't exist)
  cleanupBrokenSymlinks = dir: type: ''
    if [ -d "${dir}" ]; then
      # Use find and while-read to avoid a for loop, per repo guidelines.
      find "${dir}" -maxdepth 1 -type l -print0 | while IFS= read -d $'\0' -r link; do
        # Check if the symlink is broken
        if [ ! -e "$link" ]; then
          if $DRY_RUN_CMD rm "$link"; then
            log_info "Removed orphan ${type}: $(basename "$link")"
          else
            log_warn "Failed to remove orphan ${type}: $(basename "$link")"
          fi
        fi
      done
    fi
  '';

  # Cache integrity verification script
  verifyCacheIntegrityScript = "${./scripts/verify-cache-integrity.sh}";

in
{
  config = lib.mkIf cfg.enable {
    home.activation = {
      # Phase 1: Remove conflicting directory symlinks BEFORE linkGeneration
      # This allows Home Manager to create individual file symlinks
      cleanupConflictingDirectorySymlinks = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
        ${logHelper}

        # Remove directory symlinks that point to nix store
        # These conflict with individual file symlinks
        ${lib.concatMapStringsSep "\n" preCleanupDir componentDirs}

        # Also clean up root-level directory symlinks if they conflict
        printf '%s\n' \
          "${homeDir}/CLAUDE.md" \
          "${homeDir}/GEMINI.md" \
          "${homeDir}/AGENTS.md" \
          "${homeDir}/agentsmd" | while IFS= read -r path; do
          if [ -L "$path" ]; then
            TARGET=$(readlink "$path")
            if [[ "$TARGET" == /nix/store/* ]] && [ ! -e "$TARGET" ]; then
              if $DRY_RUN_CMD rm "$path"; then
                log_info "Removed stale symlink: $path"
              else
                log_warn "Failed to remove stale symlink: $path"
              fi
            fi
          fi
        done
      '';

      # Phase 2: Clean up orphan symlinks AFTER linkGeneration creates new ones
      # Only cleans up symlinks INSIDE component directories (not root-level files)
      # Root-level files (CLAUDE.md, AGENTS.md, etc.) are handled by force = true
      cleanupOrphanComponents = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        ${logHelper}

        # Clean up Claude directories - only broken symlinks inside these dirs
        ${cleanupBrokenSymlinks "${homeDir}/.claude/commands" "command"}
        ${cleanupBrokenSymlinks "${homeDir}/.claude/agents" "agent"}
        ${cleanupBrokenSymlinks "${homeDir}/.claude/skills" "skill"}

        # Clean up Gemini commands - only broken symlinks inside this dir
        ${cleanupBrokenSymlinks "${homeDir}/.gemini/commands" "gemini command"}

        # NOTE: Root-level files (CLAUDE.md, GEMINI.md, AGENTS.md, agentsmd) are
        # NOT cleaned up here. They use force = true in home.file and Home Manager
        # handles their lifecycle. We only handle the pre-cleanup of stale symlinks.
      '';

      # Phase 3: Verify plugin cache integrity AFTER linkGeneration
      # When Nix updates marketplace symlinks to new store paths,
      # Claude Code's cached plugin data becomes stale.
      # See: https://github.com/anthropics/claude-code/issues/17361
      verifyCacheIntegrity = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        ${logHelper}
        log_info "Verifying marketplace cache integrity..."
        $DRY_RUN_CMD ${verifyCacheIntegrityScript} "${homeDir}"
      '';

    };
  };
}
