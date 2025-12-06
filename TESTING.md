# Testing Guide

Step-by-step procedures to verify this nix-darwin configuration is functioning correctly.

## Table of Contents

- [Variables](#variables)
- [Full Testing Procedure](#full-testing-procedure)
- [Quick Smoke Test](#quick-smoke-test)
- [Troubleshooting](#troubleshooting)

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

Validates the flake.nix structure without building.

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

### 4. Test Build (Dry Run)

```bash
cd $NIX_CONFIG_DIR
nix build .#darwinConfigurations.$FLAKE_TARGET.system --dry-run
```

Shows what would be built without actually building.

### 5. Full Rebuild

```bash
sudo darwin-rebuild switch --flake $NIX_CONFIG_DIR#$FLAKE_TARGET
```

Applies the configuration to the system.

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
sudo darwin-rebuild switch --flake $NIX_CONFIG_DIR#$FLAKE_TARGET
```

---

## Quick Smoke Test

Minimum validation for quick checks:

```bash
NIX_CONFIG_DIR=~/.config/nix
cd $NIX_CONFIG_DIR
nix flake check $NIX_CONFIG_DIR && \
  markdownlint-cli2 . && \
  echo "✓ Validation passed"
```

---

## Troubleshooting

If any test fails, consult:

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [RUNBOOK.md](RUNBOOK.md) - Operational procedures including rollback
