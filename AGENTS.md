# Nix Configuration - AI Agent Instructions

## Critical Constraints

1. **Flakes-only**: Never use `nix-env`, `nix-channels`, or imperative commands
2. **Determinate Nix**: Keep `nix.enable = false` in darwin config
3. **Nixpkgs first**: Use homebrew only when nixpkgs unavailable
4. **Worktrees required**: Run `/init-worktree` before any work
5. **No direct main commits**: Always use feature branches

## Required Build Validation

**Every `git push` and `gh pr create` MUST be immediately preceded by a passing build.**

```bash
nix flake check && sudo darwin-rebuild switch --flake .
```

- Run AFTER your final commit, BEFORE push/PR. If you commit again, re-run.
- ANY warning or error is a build failure. Fix it, re-commit, re-run.
- No exceptions. No skipping. No "CI will catch it."

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

## PR Rules

- Never auto-merge without explicit user approval
- 50-comment limit per PR
- Batch commits locally, push once
