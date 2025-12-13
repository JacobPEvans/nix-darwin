---
description: Update all flake inputs and rebuild nix-darwin
model: haiku
allowed-tools: Read, Bash(nix flake:*), Bash(git:*), Bash(gh:*), Bash(darwin-rebuild:*), Bash(sudo darwin-rebuild:*)
---

# Flake Rebuild

Update all flake inputs and rebuild nix-darwin.

**IMPORTANT**: This command uses GitHub auto-merge. The PR will automatically merge when all required status checks pass.

## Critical Rules

1. **NEVER commit to main** - Always create or switch to a feature branch FIRST
2. **NEVER manually merge** - Use `gh pr merge --auto` to enable auto-merge

## Steps

### 1. Sync Repository First

**IMPORTANT**: Before starting, run `/git-refresh` to:

- Merge any pending PRs that are ready
- Sync local main with remote
- Clean up stale worktrees

This ensures you're working with the latest code and avoids conflicts.

### 2. Pre-flight Checks

Ensure you're on main and it's clean:

```bash
git checkout main
git pull
git status
```

If there are uncommitted changes, **STOP** and report to the user.

### 3. Switch to Feature Branch

Check if the branch already exists. If it does, switch to it. If not, create it.

Branch name format: `chore/flake-update-YYYY-MM-DD` (replace with today's date)

```bash
git checkout chore/flake-update-YYYY-MM-DD 2>/dev/null || git checkout -b chore/flake-update-YYYY-MM-DD
```

### 4. Update Flake Inputs

```bash
nix flake update
```

**On failure**: Switch back to main and report the error.

### 5. Check for Changes

```bash
git status
```

- If flake.lock is **unchanged**: Switch back to main, report "All flake inputs already up to date" and **STOP**.
- If flake.lock **changed**: Continue to step 6.

### 6. Commit the Update

```bash
git add flake.lock
git commit -m "chore(deps): update flake.lock"
```

### 7. Rebuild nix-darwin

```bash
sudo darwin-rebuild switch --flake .
```

**On failure**: Report the error but continue to create the PR (the CI will also catch issues).

### 8. Push and Create PR with Auto-Merge

Push the branch:

```bash
git push -u origin HEAD
```

Create PR with the `dependencies` label (to skip Claude review), or skip if PR already exists:

```bash
gh pr view >/dev/null 2>&1 || gh pr create --fill --label dependencies
```

Enable auto-merge (this will merge automatically when checks pass):

```bash
gh pr merge --auto --squash --delete-branch
```

### 9. Return to Main

Switch back to main while waiting for auto-merge:

```bash
git checkout main
```

### 10. Report Summary

Tell the user:

1. What inputs were updated (from the nix flake update output)
2. The PR URL
3. That auto-merge is enabled and will merge when checks pass
4. They can run `git pull` after the PR merges to sync locally

**DO NOT wait for checks** - auto-merge handles this automatically.
