# Flake Rebuild

Update all flake inputs and rebuild nix-darwin.

**IMPORTANT**: This command has special auto-merge permission. Unlike normal PRs, this command may merge automatically if all conditions are met.

## Steps

### 1. Update Flake Inputs

Run `nix flake update` to update flake.lock.

**On failure**: Stop and report the error to the user.

### 2. Rebuild nix-darwin

Run `sudo darwin-rebuild switch --flake ~/.config/nix`

**On failure**: Stop and report the error to the user.

### 3. Check for Changes

Run `git diff --quiet flake.lock` to check if flake.lock changed.

**If no changes**: Report "All flake inputs already up to date" and stop.

### 4. Create Branch and Commit

1. Create and switch to branch: `git checkout -b chore/flake-update-YYYY-MM-DD` (use today's date)
2. Stage changes: `git add flake.lock`
3. Commit with message: `chore(deps): update flake.lock`

### 5. Push and Create PR

1. Push branch: `git push -u origin HEAD`
2. Create PR: `gh pr create --title "chore(deps): update flake.lock" --body "Automated flake input updates."`

### 6. Wait for Checks and Auto-Merge

1. Wait for all PR checks to complete: `gh pr checks --watch`
2. Check if PR is mergeable: `gh pr view --json mergeable,mergeStateStatus`
3. **IF AND ONLY IF** all checks pass and PR is mergeable:
   - Squash merge: `gh pr merge --squash --delete-branch`
   - Switch back to main: `git checkout main && git pull`
4. **If checks fail or not mergeable**: Report status to user and do NOT merge

### 7. Report Summary

Report what inputs were updated (summarize flake.lock diff from the commit).
