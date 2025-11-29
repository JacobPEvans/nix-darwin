# Git utility functions

# gitmd - Merge and delete branch
# Usage: gitmd <target-branch> <source-branch>
# Example: gitmd main feature/my-feature
gitmd() {
  # $1 - Target Branch
  # $2 - Source Branch

  # Exit on failure
  set -e

  if [[ "$2" == "main" ]]; then
    echo "ERROR: Cannot delete main branch"
    return 1
  fi

  git checkout "$1"
  git merge "$2"
  git branch -D "$2"
}
