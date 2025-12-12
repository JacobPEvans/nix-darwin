# Claude Plugin Migration Specification

Migrate from custom Claude commands to official Anthropic plugins, managed declaratively via Nix.

## Overview

This specification outlines the migration from custom Claude Code commands to official Anthropic
plugins. The migration leverages officially maintained plugins while preserving unique
functionality that does not exist in official offerings.

**Issue**: [#78](https://github.com/JacobPEvans/nix/issues/78)

### Scope

| In Scope | Out of Scope |
|----------|--------------|
| Remove redundant custom commands | Modifying official plugin behavior |
| Update `claude.nix` configuration | Creating new custom commands |
| Verify official plugins work correctly | Agent OS command changes |
| Update documentation | Permission file changes |

## Migration Decisions

### Commands REMOVED (replaced by official plugins)

| Custom Command | Official Replacement | Status |
|----------------|---------------------|--------|
| `commit` (ai-instructions) | `/commit` from `commit-commands` plugin | ✅ Removed |
| `review-pr-ci` (cookbook) | `/code-review` from `code-review` plugin | ✅ Removed |
| `review-pr` (cookbook) | `/code-review` from `code-review` plugin | ✅ Removed |

### Commands RETAINED (unique functionality)

**Git/PR Workflow**: `pull-request`, `git-refresh`, `pull-request-review-feedback`

**Reviews**: `review-code`, `review-docs`, `review-issue`, `infrastructure-review`, `link-review`

**Specialized**: `model-check`, `notebook-review`, `generate-code`

**ROK/Shape Up**: `rok-shape-issues`, `rok-resolve-issues`, `rok-review-pr`, `rok-respond-to-reviews`

## Files Modified

| File | Change |
|------|--------|
| `modules/home-manager/ai-cli/claude.nix` | Remove `commit` from list |
| `modules/home-manager/ai-cli/claude-plugins.nix` | Remove `review-pr-ci`, `review-pr` |
| `docs/ANTHROPIC-ECOSYSTEM.md` | Update counts, add Migration Notes |
| `CLAUDE.md` | Update cookbook command count |

## Final Command Inventory

### Cookbook Commands (4)

`review-issue`, `notebook-review`, `model-check`, `link-review`

### Custom Commands (11)

`generate-code`, `git-refresh`, `infrastructure-review`, `pull-request`,
`pull-request-review-feedback`, `review-code`, `review-docs`,
`rok-resolve-issues`, `rok-respond-to-reviews`, `rok-review-pr`, `rok-shape-issues`

### Agent OS Commands (7, unchanged)

`create-tasks`, `implement-tasks`, `improve-skills`, `orchestrate-tasks`,
`plan-product`, `shape-spec`, `write-spec`

## Rollback

```bash
# Immediate: revert to previous Nix generation
darwin-rebuild switch --rollback

# Git: revert migration commit
git revert HEAD --no-edit && darwin-rebuild switch --flake .
```

## References

- [ANTHROPIC-ECOSYSTEM.md](../../docs/ANTHROPIC-ECOSYSTEM.md) - Migration notes section
- [tasks.md](tasks.md) - Detailed implementation tasks
