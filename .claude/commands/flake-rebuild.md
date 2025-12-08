---
description: Update all flake inputs and rebuild nix-darwin
model: haiku
allowed-tools: Read, Bash(nix flake:*), Bash(git:*), Bash(gh:*), Bash(darwin-rebuild:*), Bash(sudo darwin-rebuild:*)
---

# Flake Rebuild

Update all flake inputs and rebuild nix-darwin.

**IMPORTANT**: This command has special auto-merge permission. Unlike normal PRs, this command may merge automatically if all conditions are met.

## Steps

### 1. Update Flake Inputs

Run this exact command:
```bash
nix flake update
```

**On failure**: Stop and report the error to the user.

### 2. Check for Changes

Run `git status` to check if flake.lock changed.

- If flake.lock is **unchanged**: Report "All flake inputs already up to date" and **STOP**.
- If flake.lock **changed**: Continue to step 3.

### 3. Create Feature Branch

Run these commands (replace YYYY-MM-DD with today's date):
```bash
git checkout -b chore/flake-update-YYYY-MM-DD
```

### 4. Commit the Update

Run:
```bash
git add flake.lock
git commit -m "chore(deps): update flake.lock"
```

### 5. Rebuild nix-darwin

Run this exact command:
```bash
sudo darwin-rebuild switch --flake .
```

**On failure**: Stop and report the error to the user.

### 6. Push and Create PR

Run:
```bash
git push -u origin HEAD
gh pr create --fill
```

### 7. Wait for Checks and Auto-Merge

Run `gh pr checks --watch`. Then:

- If **all checks pass**: Run `gh pr merge --squash --delete-branch` and `git checkout main && git pull`
- If **checks fail**: Report status and do NOT merge.

### 8. Report Summary

Tell the user what inputs were updated (from the nix flake update output).
