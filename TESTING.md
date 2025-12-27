# Testing Guide

Step-by-step procedures to verify this nix-darwin configuration is functioning correctly.

> **Warning**: ALL warnings and errors from `nix flake check` and `darwin-rebuild`
> MUST be resolved before proceeding. Do NOT continue past any command that produces
> warnings or errors. This applies to every test in this document.

---

## Table of Contents

- [Basic Local Change Testing](#basic-local-change-testing)
- [Variables](#variables)
- [Full Testing Procedure](#full-testing-procedure)
- [Quick Smoke Test](#quick-smoke-test)
- [Troubleshooting](#troubleshooting)

---

## Basic Local Change Testing

**Core test command for any nix configuration change.**

```bash
sudo /nix/var/nix/profiles/system/activate && sudo darwin-rebuild switch --flake .
```

> **Note**: The activation prefix ensures the current-system symlink is updated
> before rebuilding. This prevents activation verification failures.

**Prerequisites:**

- All changes must be committed first (Nix flakes requirement)
- Pre-commit hooks run automatically on `git commit`

**Note:** For the complete git workflow (staging, committing, pushing), see
[CLAUDE.md](CLAUDE.md#after-completing-changes) which is the single source of truth.

---

## Variables

Set these variables before running tests. Adjust if paths change:

```bash
NIX_CONFIG_DIR=~/.config/nix
FLAKE_TARGET=default
```

---

## Full Testing Procedure

### 1. Validate Flake Syntax

```bash
nix flake check $NIX_CONFIG_DIR
```

Validates the flake.nix structure without building. **Stop and fix any warnings or errors.**

### 2. Validate Markdown Linting

```bash
cd $NIX_CONFIG_DIR
markdownlint-cli2 .
```

Ensures all documentation passes linting (required for CI).

### 3. Verify Git State

```bash
cd $NIX_CONFIG_DIR
git status
```

All changes must be committed before rebuild (flakes requirement).

### 4. Validate Flake

```bash
cd $NIX_CONFIG_DIR
nix flake check
```

Validates the flake structure and runs checks. **Stop and fix any warnings or errors.**

### 5. Full Rebuild

```bash
sudo /nix/var/nix/profiles/system/activate && sudo darwin-rebuild switch --flake $NIX_CONFIG_DIR
```

Applies the configuration to the system. **Stop and fix any warnings or errors.**

### 6. Verify Nix PATH Priority

```bash
echo $PATH | tr ':' '\n' | head -10
```

**Expected order**:

1. `~/.nix-profile/bin`
2. `/etc/profiles/per-user/$USER/bin`
3. `/run/current-system/sw/bin` ← nix packages
4. `/nix/var/nix/profiles/default/bin`
5. `/opt/homebrew/bin` ← fallback only

### 7. Verify Key Packages

```bash
which bat delta eza fd fzf rg jq claude
```

All should show `/run/current-system/sw/bin/...`

### 8. Verify Dev Shells

```bash
nix develop $NIX_CONFIG_DIR#python --command python --version
nix develop $NIX_CONFIG_DIR#js --command node --version
```

### 9. Verify Claude Code Configuration

```bash
cat ~/.claude/settings.json | jq '.permissions' | head -20
ls ~/.claude/commands/
ls ~/.claude/agents/
```

### 10. Rollback Test (Optional)

```bash
sudo darwin-rebuild --list-generations
sudo darwin-rebuild --rollback
# Then switch back
sudo /nix/var/nix/profiles/system/activate && sudo darwin-rebuild switch --flake $NIX_CONFIG_DIR
```

---

## Quick Smoke Test

Minimum validation for quick checks. **Any warnings or errors = stop and fix.**

```bash
NIX_CONFIG_DIR=~/.config/nix
cd $NIX_CONFIG_DIR
nix flake check $NIX_CONFIG_DIR && \
  markdownlint-cli2 . && \
  echo "✓ Validation passed"
```

---

## Fresh, Non-Cached Nix Rebuild

When debugging issues where changes don't take effect, use these techniques to ensure
a completely fresh build without caching.

### Step 1: Verify All Changes Are Committed

```bash
git status --porcelain
```

Nix flakes only use **committed** changes. Uncommitted files will NOT be included in
the build, even if the flake warns about "uncommitted changes".

### Step 2: Force Lock File Recreation

```bash
sudo darwin-rebuild switch --flake . --recreate-lock-file
```

This rebuilds the flake.lock from scratch, forcing re-evaluation of all inputs.

### Step 3: Full Garbage Collection + Rebuild

For maximum freshness (takes longer):

```bash
nix-collect-garbage -d
nix store gc
sudo /nix/var/nix/profiles/system/activate && sudo darwin-rebuild switch --flake .
```

### Step 4: Verify New Derivations

After rebuild, check that derivations actually changed:

```bash
# Check settings.json source path
readlink ~/.claude/settings.json

# Each rebuild with changes should produce a NEW store path
# If the path is the same as before, the changes weren't picked up
```

### Common Causes of "Changes Not Applied"

1. **Uncommitted changes**: Nix flakes require `git commit` before changes take effect
2. **Duplicate code paths**: Multiple modules generating the same file (see below)
3. **Module not imported**: Check flake.nix imports and home-manager sharedModules
4. **Cached evaluation**: Use `--recreate-lock-file` to force re-evaluation

---

## Debugging Duplicate Code Paths

This repository has multiple files that transform marketplace data for Claude settings.
If changes to one file don't work, check if another file is the actual source:

### Files That Generate `extraKnownMarketplaces`

| File | Purpose | Used By |
| --- | --- | --- |
| `modules/home-manager/ai-cli/claude/settings.nix` | HOME-MANAGER deployment | programs.claude module |
| `lib/claude-settings.nix` | CI validation | flake.nix ciClaudeSettings |
| `lib/claude-registry.nix` | Registry generation | known_marketplaces.json |

### How to Trace Which Module Generates settings.json

```bash
# Check the current settings.json source
readlink -f ~/.claude/settings.json

# List Claude-related derivations in home-manager
nix-store --query --references ~/.local/state/home-manager/gcroots/current-home | grep claude
```

### Single Source of Truth Pattern

When adding transformation logic, ensure ALL three files use the same pattern:

```nix
# Correct: Use repo for github/git types
if m.source.type == "github" || m.source.type == "git" then
  { source = "github"; repo = name; }
else
  { source = m.source.type; inherit (m.source) url; }
```

---

## Troubleshooting

If any test fails, consult:

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [RUNBOOK.md](RUNBOOK.md) - Operational procedures including rollback
