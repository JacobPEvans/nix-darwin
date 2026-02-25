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

## Repository Structure

This repo uses a bare git repo with worktrees:

- `~/git/nix-config/` - bare repo (do not cd here directly)
- `~/git/nix-config/main/` - main branch worktree
- `~/git/nix-config/<branch-name>/` - feature worktrees

## Steps

### 1. Sync Main Worktree First

**IMPORTANT**: Update the main worktree before starting:

```bash
cd ~/git/nix-config/main
git fetch origin
git pull origin main
git status
```

If there are uncommitted changes, **STOP** and report to the user.

### 2. Create or Switch to Feature Worktree

Branch/worktree name format: `chore/flake-update-YYYY-MM-DD` (replace with today's date)

Check if worktree already exists, otherwise create it:

```bash
cd ~/git/nix-config
# Check if worktree exists
if [ -d "chore/flake-update-YYYY-MM-DD" ]; then
  cd chore/flake-update-YYYY-MM-DD
  git pull origin main  # Update with latest main
else
  git worktree add chore/flake-update-YYYY-MM-DD -b chore/flake-update-YYYY-MM-DD origin/main
  cd chore/flake-update-YYYY-MM-DD
fi
```

### 3. Update ALL Flake Inputs

**IMPORTANT**: Update the root flake AND all shell/module flakes throughout the repository.

Use the centralized update script to avoid DRY violations:

```bash
./scripts/update-all-flakes.sh
```

**Script reference**: See `scripts/update-all-flakes.sh` in the repository root.

The script updates:

- Root flake.lock (darwin, home-manager, nixpkgs, AI tools)
- Shell environment flakes (shells/**/flake.lock)
- Host-specific flakes (hosts/**/flake.lock)

**On failure**: Report the error and stop.

### 4. Check for Changes

```bash
git status --short
```

- If **no changes**: Report "All flake inputs already up to date" and **STOP**.
- If **changes detected**: Continue to step 5.

### 5. Commit the Updates

```bash
# Add all modified and new flake.lock files
git add */flake.lock flake.lock 2>/dev/null || true
git add shells/*/flake.lock hosts/*/flake.lock 2>/dev/null || true

# Create a descriptive commit message
git commit -m "chore(deps): update all flake inputs

Updated nixpkgs and other inputs across:
- Root flake
- Shell environments
- Host configurations"
```

### 6. Rebuild nix-darwin

```bash
sudo darwin-rebuild switch --flake .
```

**On failure**: Report the error but continue to create the PR (the CI will also catch issues).

### 7. Push and Create PR with Auto-Merge

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

### 8. Return to Main Worktree

Switch back to the main worktree while waiting for auto-merge:

```bash
cd ~/git/nix-config/main
```

### 9. Report Summary

Tell the user:

1. What inputs were updated (from the nix flake update output)
2. The PR URL
3. That auto-merge is enabled and will merge when checks pass
4. They can run `git pull` in the main worktree after the PR merges

**DO NOT wait for checks** - auto-merge handles this automatically.

**Note**: The worktree at `~/git/nix-config/chore/flake-update-YYYY-MM-DD/` will be automatically
cleaned up by auto-claude after the PR is merged.
