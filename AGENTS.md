# Nix Configuration - AI Agent Instructions

## Critical Constraints

1. **Flakes-only**: Never use `nix-env`, `nix-channels`, or imperative commands
2. **Determinate Nix**: Keep `nix.enable = false` in darwin config
3. **Nixpkgs first**: Use homebrew only when nixpkgs unavailable
4. **Worktrees required**: Run `/init-worktree` before any work
5. **No direct main commits**: Always use feature branches

## Build Validation

Build validation is enforced by **GitHub Actions CI** (`ci-gate.yml`) on every PR — not by a local pre-push hook.

Local quick checks (formatting, linting, dead code) run automatically on every commit via pre-commit hooks:

```bash
nix fmt         # fix formatting
statix check    # lint
deadnix         # dead code
```

A full `nix flake check && sudo darwin-rebuild switch --flake .` is run by CI on macOS runners and must
pass before merge. You may run it locally to verify before pushing, but it is not required locally.

## Worktree Workflow

```bash
cd ~/git/nix-config
git fetch origin
git worktree add <branch> -b <branch> origin/main
cd <branch>
```

## File References

- **Permissions**: `ai-assistant-instructions` flake → `~/.claude/settings.json`
- **Plugins**: `modules/home-manager/ai-cli/claude/plugins/`
- **Rules**: `agentsmd/rules/` (worktrees, version-validation, skill-namespace-resolution, security-alert-triage)
- **Security**: See SECURITY.md and `agentsmd/rules/security-alert-triage.md` for alert policies
- **Inventory**: `MANIFEST.md` — update when adding/removing packages

## PR Rules

- Never auto-merge without explicit user approval
- 50-comment limit per PR
- Batch commits locally, push once
