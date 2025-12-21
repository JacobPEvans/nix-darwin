# Git and GitHub CLI Commands
#
# Auto-approved git and gh commands.
# Imported by allow.nix - do not use directly.

_:

{
  # --- Git Operations ---
  git = {
    read = [
      "git status"
      "git log"
      "git diff"
      "git show"
      "git blame"
      "git shortlog"
      "git describe"
      "git rev-parse"
      "git ls-files"
      "git ls-remote"
      "git ls-tree"
      "git cat-file"
      "git reflog"
      "git for-each-ref"
      "git name-rev"
      "git rev-list"
      "git merge-base"
    ];
    branch = [
      "git branch"
      "git checkout"
      "git switch"
      "git tag"
      "git worktree list"
      "git worktree add"
      "git worktree remove"
      "git worktree prune"
    ];
    write = [
      "git add"
      "git commit"
      "git stash"
      "git mv"
    ];
    remote = [
      "git push"
      "git pull"
      "git fetch"
      "git remote"
      "git clone"
      "git merge"
      "git rebase"
    ];
    config = [
      "git config"
      "git gc"
      "git prune"
      "git fsck"
    ];
  };

  # --- GitHub CLI ---
  gh = {
    auth = [ "gh auth status" ];
    pr = [
      "gh pr list"
      "gh pr view"
      "gh pr create"
      "gh pr checkout"
      "gh pr merge"
      "gh pr diff"
      "gh pr comment"
      "gh pr checks"
      "gh pr edit"
      "gh pr ready"
    ];
    issue = [
      "gh issue list"
      "gh issue view"
      "gh issue create"
      "gh issue edit"
      "gh issue comment"
    ];
    repo = [
      "gh repo view"
      "gh repo clone"
    ];
    api = [
      "gh api"
      "gh api graphql"
    ];
    ci = [
      "gh run list"
      "gh run view"
      "gh run watch"
      "gh run rerun"
      "gh workflow list"
      "gh workflow view"
    ];
    misc = [
      "gh release list"
      "gh release view"
      "gh search"
      "gh gist view"
      "gh label list"
    ];
  };
}
