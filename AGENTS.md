# Nix Configuration - AI Agent Instructions

## Critical Constraints

1. **Flakes-only**: Never use `nix-env`, `nix-channels`, or imperative commands
2. **Determinate Nix**: Keep `nix.enable = false` in darwin config
3. **Nixpkgs first**: Use homebrew only when nixpkgs unavailable
4. **Worktrees required**: Run `/init-worktree` before any work
5. **No direct main commits**: Always use feature branches

## Worktree Workflow

```bash
cd ~/git/nix-config
git fetch origin
git worktree add <branch> -b <branch> origin/main
cd <branch>
```

## Test & Deploy

**CRITICAL**: MUST run BOTH commands before every push/PR creation:

```bash
nix flake check
sudo darwin-rebuild switch --flake .
```

These are NOT optional deployment steps - they are REQUIRED testing:

- `nix flake check`: Validates flake syntax and structure
- `sudo darwin-rebuild switch`: Tests that changes actually work in production

**Never push or create a PR without running both commands successfully.**

## File References

- **Permissions**: `ai-assistant-instructions` flake → `~/.claude/settings.json`
- **Plugins**: `modules/home-manager/ai-cli/claude/plugins/`
- **Rules**: `agentsmd/rules/` (worktrees, version-validation, skill-namespace-resolution, security-alert-triage)
- **Security**: See SECURITY.md and `agentsmd/rules/security-alert-triage.md` for alert policies

## Skill and Agent Invocation Rules

See the "Skill and Agent Invocation Rules" section below for complete instructions on
invoking skills and agents correctly. This covers namespace format, common mistakes, and
error resolution procedures.

## PR Rules

- Never auto-merge without explicit user approval
- 50-comment limit per PR
- Batch commits locally, push once
