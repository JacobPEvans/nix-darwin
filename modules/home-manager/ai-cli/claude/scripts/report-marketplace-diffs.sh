#!/usr/bin/env bash
# Show diffs between backed-up directories and new Nix-managed symlinks
# Backups are kept for manual review and deletion
#
# Arguments:
#   $@: MARKETPLACE_PATHS - space-separated list of marketplace paths

MARKETPLACE_PATHS=("$@")

for path in "${MARKETPLACE_PATHS[@]}"; do
  BACKUP="$path.backup"
  if [ -d "$BACKUP" ]; then
    echo "" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Marketplace update: $path" >&2

    if [ -L "$path" ]; then
      NEW_TARGET=$(readlink "$path")
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
        diff_output=$(diff -r "$BACKUP" "$path" 2>&1 | head -20)
        diff_exit=${PIPESTATUS[0]}

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
done
