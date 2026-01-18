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

```bash
nix flake check
sudo darwin-rebuild switch --flake .
```

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

## Dependency Management

### Claude Code Update Philosophy

Claude Code and related AI tool dependencies follow an **always-update strategy**:

- **Auto-update Daily**: Daily flake updates automatically include claude-code, claude-code-plugins, and jacobpevans-cc-plugins
- **Manual Validation**: After updating, manually test and validate new versions during CI and darwin-rebuild
- **Accept by Default**: Merge PR unless issues are discovered during validation
- **Revert on Issues**: Only revert updates if testing reveals bugs, breaking changes, or integration problems

This aggressive update approach keeps Claude Code current with latest features, bug
fixes, and improvements, while maintaining reliability through manual testing gates.

### AI-Focused Inputs

The following inputs update daily (when not on Tue/Fri full-update schedule):

- nixpkgs (stable channel)
- ai-assistant-instructions
- claude-code-plugins (official Anthropic)
- claude-cookbooks
- claude-plugins-official
- jacobpevans-cc-plugins (personal custom plugins)
- anthropic-skills
- superpowers-marketplace
- agent-os
