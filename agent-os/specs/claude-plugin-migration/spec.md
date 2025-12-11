# Claude Plugin Migration Specification

Migrate from custom Claude commands to official Anthropic plugins, managed declaratively via Nix.

## Table of Contents

- [Overview](#overview)
- [Goals](#goals)
- [Non-Goals](#non-goals)
- [Current State Analysis](#current-state-analysis)
- [Target State](#target-state)
- [Technical Approach](#technical-approach)
- [Implementation Phases](#implementation-phases)
- [Testing Strategy](#testing-strategy)
- [Rollback Plan](#rollback-plan)
- [Success Criteria](#success-criteria)
- [Risk Assessment](#risk-assessment)
- [Open Questions](#open-questions)

---

## Overview

This specification outlines the migration from custom Claude Code commands to official Anthropic
plugins. The migration leverages officially maintained plugins while preserving unique
functionality that does not exist in official offerings.

### Background

The current Claude Code setup uses a hybrid approach:

- **12 official plugins** from `anthropics/claude-code` marketplace
- **6 cookbook commands** from `anthropics/claude-cookbooks`
- **12 custom commands** from `ai-assistant-instructions` repository
- **7 Agent OS commands** from `agent-os` repository

This creates redundancy where custom commands duplicate functionality now available in official plugins.

### Scope

| In Scope | Out of Scope |
|----------|--------------|
| Remove redundant custom commands | Modifying official plugin behavior |
| Update `claude.nix` configuration | Creating new custom commands |
| Verify official plugins work correctly | Agent OS command changes |
| Update documentation | Permission file changes |
| Rename commands to avoid confusion | SDK development shell changes |

---

## Goals

1. **Reduce maintenance burden** - Leverage officially maintained plugins instead of custom implementations
2. **Ensure feature parity** - All current functionality remains available (either via official plugins or retained custom commands)
3. **Maintain declarative management** - All changes managed via Nix for reproducibility
4. **Clear command naming** - Avoid confusion between custom and official commands
5. **Documentation alignment** - Update docs to reflect new command structure

---

## Non-Goals

1. Replacing unique custom commands that have no official equivalent
2. Modifying the plugin marketplace configuration
3. Changing Agent OS integration or commands
4. Altering the permission management system
5. Migrating to a non-Nix configuration approach

---

## Current State Analysis

### Official Plugins Currently Enabled (12)

From `modules/home-manager/ai-cli/claude-plugins.nix`:

| Plugin | Marketplace | Commands/Features |
|--------|-------------|-------------------|
| commit-commands | anthropics/claude-code | `/commit`, `/commit-push-pr`, `/clean_gone` |
| code-review | anthropics/claude-code | Multi-agent PR review with confidence scoring |
| pr-review-toolkit | anthropics/claude-code | 6 specialized review agents |
| feature-dev | anthropics/claude-code | 7-phase feature development workflow |
| security-guidance | anthropics/claude-code | PreToolUse security monitoring hook |
| plugin-dev | anthropics/claude-code | `/plugin-dev:create-plugin` |
| hookify | anthropics/claude-code | `/hookify`, `/hookify:list`, `/hookify:configure` |
| agent-sdk-dev | anthropics/claude-code | `/new-sdk-app` |
| frontend-design | anthropics/claude-code | UI/UX design skill |
| explanatory-output-style | anthropics/claude-code | Educational insights hook |
| learning-output-style | anthropics/claude-code | Interactive learning mode |
| claude-opus-4-5-migration | anthropics/claude-code | Model migration skill |

### Cookbook Commands Currently Installed (6)

From `modules/home-manager/ai-cli/claude-plugins.nix`:

| Command | Description |
|---------|-------------|
| `review-pr-ci` | CI/CD PR review (auto-posts to GitHub) |
| `review-pr` | Interactive PR review |
| `review-issue` | GitHub issue review |
| `notebook-review` | Jupyter notebook review |
| `model-check` | Model validation |
| `link-review` | Link verification |

### Custom Commands from ai-assistant-instructions (12)

From `modules/home-manager/ai-cli/claude.nix`:

| Command | Category | Description |
|---------|----------|-------------|
| `commit` | Git | Standardized git commit process |
| `generate-code` | Development | Code generation standards |
| `git-refresh` | Git | Branch refresh workflow |
| `infrastructure-review` | Review | Terraform/Terragrunt review |
| `pull-request` | Git | PR lifecycle management |
| `pull-request-review-feedback` | Git | Address PR feedback |
| `review-code` | Review | Structured code review |
| `review-docs` | Review | Markdown validation |
| `rok-resolve-issues` | ROK | Implement shaped issues |
| `rok-respond-to-reviews` | ROK | Address PR feedback |
| `rok-review-pr` | ROK | Comprehensive PR review |
| `rok-shape-issues` | ROK | Transform ideas into issues |

### Agent OS Commands (7)

From `modules/home-manager/ai-cli/agent-os/default.nix`:

| Command | Description |
|---------|-------------|
| `create-tasks` | Break spec into tasks |
| `implement-tasks` | Execute implementation |
| `improve-skills` | Skill improvement loop |
| `orchestrate-tasks` | Multi-task coordination |
| `plan-product` | Product planning workflow |
| `shape-spec` | Specification shaping |
| `write-spec` | Write technical specification |

---

## Target State

### Commands to REMOVE (replaced by official plugins)

| Custom Command | Official Replacement | Rationale |
|----------------|---------------------|-----------|
| `commit` | `commit-commands` plugin (`/commit`) | Official plugin provides identical functionality |
| `review-pr-ci` (cookbook) | `code-review` plugin | Official plugin has CI integration capabilities |

### Commands to KEEP (unique functionality)

#### Git/PR Workflow (3)

| Command | Reason to Keep |
|---------|----------------|
| `pull-request` | Complete PR lifecycle management with project-specific conventions |
| `git-refresh` | Custom branch refresh workflow with stash handling |
| `pull-request-review-feedback` | Project-specific feedback handling |

#### Reviews (5)

| Command | Reason to Keep |
|---------|----------------|
| `review-code` | Structured code review with project-specific priority levels |
| `review-docs` | Markdown validation workflow specific to documentation standards |
| `review-issue` (cookbook) | GitHub issue review (no official equivalent) |
| `infrastructure-review` | Terraform/Terragrunt specific review checklist |
| `link-review` (cookbook) | Link verification (no official equivalent) |

#### Specialized (3)

| Command | Reason to Keep |
|---------|----------------|
| `model-check` (cookbook) | Model validation (no official equivalent) |
| `notebook-review` (cookbook) | Jupyter notebook review (no official equivalent) |
| `generate-code` | Code generation with project-specific guidelines |

#### ROK/Shape Up (4)

| Command | Reason to Keep |
|---------|----------------|
| `rok-shape-issues` | Shape Up methodology for issue creation |
| `rok-resolve-issues` | Shape Up issue implementation workflow |
| `rok-review-pr` | Comprehensive PR review with Shape Up practices |
| `rok-respond-to-reviews` | Systematic PR feedback handling |

### Cookbook Commands to REMOVE

| Command | Reason to Remove |
|---------|------------------|
| `review-pr-ci` | Replaced by `code-review` plugin |
| `review-pr` | Potentially redundant with `code-review` plugin (needs verification) |

### Potential Command Renaming

To avoid confusion between custom and official commands:

| Current Name | Suggested Name | Reason |
|--------------|---------------|--------|
| `review-code` | (keep as-is) | Distinct from `/code-review` plugin |
| `rok-review-pr` | (keep as-is) | ROK prefix distinguishes from official |

---

## Technical Approach

### Phase 1: Configuration Updates

**File: `modules/home-manager/ai-cli/claude.nix`**

Update `aiInstructionsCommands` list to remove redundant commands:

```nix
# BEFORE
aiInstructionsCommands = [
  "commit"  # REMOVE - replaced by commit-commands plugin
  "generate-code"
  "git-refresh"
  # ... rest of commands
];

# AFTER
aiInstructionsCommands = [
  "generate-code"
  "git-refresh"
  # ... rest of commands (without "commit")
];
```

**File: `modules/home-manager/ai-cli/claude-plugins.nix`**

Update `cookbookCommands` list to remove redundant commands:

```nix
# BEFORE
cookbookCommands = [
  "review-pr-ci"  # REMOVE - replaced by code-review plugin
  "review-pr"      # VERIFY - may be redundant with code-review plugin
  "review-issue"
  "notebook-review"
  "model-check"
  "link-review"
];

# AFTER (pending review-pr verification)
cookbookCommands = [
  "review-pr"      # KEEP if unique functionality confirmed
  "review-issue"
  "notebook-review"
  "model-check"
  "link-review"
];
```

### Phase 2: Documentation Updates

**File: `docs/ANTHROPIC-ECOSYSTEM.md`**

1. Update "Cookbook Commands" section to reflect removals
2. Add migration notes for users of removed commands
3. Update command count references

**File: `CLAUDE.md`**

1. Update "Anthropic Ecosystem Integration" section
2. Update command references in workflow documentation

**File: `.ai-instructions/INSTRUCTIONS.md`**

1. Update command table to reference official plugins where applicable

### Phase 3: Verification

1. Run `nix flake check` to validate configuration
2. Run `darwin-rebuild switch` to apply changes
3. Test official plugin commands work correctly
4. Test retained custom commands still function
5. Verify no orphaned symlinks in `~/.claude/commands/`

---

## Implementation Phases

### Phase 1: Analysis and Validation (Day 1)

**Objective:** Confirm official plugin functionality matches removed commands

**Tasks:**

1. Test `commit-commands` plugin `/commit` command against custom `commit.md`
2. Test `code-review` plugin against `review-pr-ci` cookbook command
3. Document any feature gaps between official and custom commands
4. Create backup of current configuration

**Deliverables:**

- Feature comparison matrix
- Decision log for each command removal
- Configuration backup

### Phase 2: Configuration Changes (Day 2)

**Objective:** Update Nix configuration files

**Tasks:**

1. Remove `commit` from `aiInstructionsCommands` in `claude.nix`
2. Remove `review-pr-ci` from `cookbookCommands` in `claude-plugins.nix`
3. Add comments documenting migration decisions
4. Run `nix flake check`

**Deliverables:**

- Updated `claude.nix`
- Updated `claude-plugins.nix`
- Passing `nix flake check`

### Phase 3: Build and Test (Day 2)

**Objective:** Apply changes and verify functionality

**Tasks:**

1. Run `darwin-rebuild switch --flake .`
2. Verify official plugins load correctly
3. Test each official plugin command
4. Test each retained custom command
5. Check `~/.claude/commands/` for expected files

**Deliverables:**

- Successful rebuild
- Test results log
- Screenshot/log of `/help` showing correct commands

### Phase 4: Documentation (Day 3)

**Objective:** Update all documentation

**Tasks:**

1. Update `docs/ANTHROPIC-ECOSYSTEM.md`
2. Update `CLAUDE.md` command references
3. Update `.ai-instructions/INSTRUCTIONS.md`
4. Add migration notes for users

**Deliverables:**

- Updated documentation files
- Migration guide section

### Phase 5: Final Verification (Day 3)

**Objective:** Complete testing and close out

**Tasks:**

1. Full end-to-end test of development workflow
2. Verify no regression in daily usage patterns
3. Create PR with all changes
4. Request review

**Deliverables:**

- Pull request
- Final test report
- Issue closure

---

## Testing Strategy

### Unit Tests

| Test | Command | Expected Outcome |
|------|---------|------------------|
| Plugin marketplace loads | `cat ~/.claude/settings.json \| jq '.marketplaces'` | Two marketplaces configured |
| Enabled plugins list | `cat ~/.claude/settings.json \| jq '.enabledPlugins'` | 12 plugins enabled |
| Custom commands symlinked | `ls -la ~/.claude/commands/` | Expected .md files present |
| Official plugin commands available | `/help` in Claude Code | Plugin commands listed |

### Integration Tests

| Test | Steps | Expected Outcome |
|------|-------|------------------|
| Official commit workflow | 1. Make change 2. Run `/commit` | Commit created successfully |
| Official code review | 1. Open PR 2. Run `/code-review` | Review comments generated |
| Custom PR workflow | 1. Create branch 2. Run `/pull-request` | PR created with correct format |
| Custom review workflow | 1. Open PR 2. Run `/rok-review-pr` | ROK review completed |

### Regression Tests

| Test | Steps | Expected Outcome |
|------|-------|------------------|
| Full development cycle | 1. Create branch 2. Make changes 3. Commit 4. Create PR 5. Review | All steps complete without error |
| CI integration | Push to branch with PR | GitHub Actions run, no failures |
| Permission patterns | Run pre-approved commands | No permission prompts |

### Rollback Verification

| Test | Steps | Expected Outcome |
|------|-------|------------------|
| Git rollback | `git revert HEAD` | Previous configuration restored |
| Rebuild after rollback | `darwin-rebuild switch` | Original commands available |

---

## Rollback Plan

### Immediate Rollback (< 5 minutes)

If issues discovered immediately after rebuild:

```bash
# Revert to previous generation
darwin-rebuild switch --rollback
```

### Git Rollback (< 15 minutes)

If issues discovered after git commit:

```bash
# Revert the migration commit
git revert HEAD --no-edit

# Rebuild
darwin-rebuild switch --flake .
```

### Full Recovery (< 30 minutes)

If both above methods fail:

1. Restore configuration from backup:

   ```bash
   cp ~/backups/claude.nix.backup modules/home-manager/ai-cli/claude.nix
   cp ~/backups/claude-plugins.nix.backup modules/home-manager/ai-cli/claude-plugins.nix
   ```

2. Commit and rebuild:

   ```bash
   git add -A
   git commit -m "chore: rollback plugin migration"
   darwin-rebuild switch --flake .
   ```

### Backup Checklist

Before starting migration:

- [ ] `cp modules/home-manager/ai-cli/claude.nix ~/backups/claude.nix.backup`
- [ ] `cp modules/home-manager/ai-cli/claude-plugins.nix ~/backups/claude-plugins.nix.backup`
- [ ] `cp ~/.claude/settings.json ~/backups/settings.json.backup`
- [ ] Note current Nix generation: `darwin-rebuild switch --list-generations | tail -1`

---

## Success Criteria

### Must Have

- [ ] All 12 official plugins enabled and functional
- [ ] `commit` command removed from `aiInstructionsCommands`
- [ ] `review-pr-ci` removed from `cookbookCommands`
- [ ] `nix flake check` passes
- [ ] `darwin-rebuild switch` succeeds without errors
- [ ] Official `/commit` command works correctly
- [ ] Official `/code-review` command works correctly
- [ ] All retained custom commands function correctly
- [ ] No orphaned symlinks in `~/.claude/commands/`

### Should Have

- [ ] Documentation updated in all relevant files
- [ ] Migration notes added for users of removed commands
- [ ] Command naming does not cause user confusion
- [ ] No regression in daily development workflow

### Nice to Have

- [ ] Performance improvement from reduced command loading
- [ ] Simplified maintenance going forward
- [ ] Clear audit trail of migration decisions

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Official plugin behavior differs from custom | Medium | High | Thorough testing in Phase 1 |
| Missing features in official plugins | Low | Medium | Keep custom command if gap found |
| Build failure after changes | Low | Low | Incremental changes, frequent checks |
| Documentation out of sync | Medium | Low | Documentation phase before merge |
| User confusion from command changes | Medium | Medium | Clear migration notes, naming review |

---

## Open Questions

1. **`review-pr` cookbook command vs `code-review` plugin:** Are these functionally equivalent, or does `review-pr` provide unique value?

2. **Plugin command prefixes:** Do official plugin commands use prefixes (e.g., `/commit-commands:commit`) or short names (e.g., `/commit`)?

3. **Command discovery timing:** When are official plugin commands discovered - at Claude Code startup or on-demand?

4. **Feature flags:** Should removed commands be gated behind a feature flag during initial rollout?

5. **Backwards compatibility:** Should aliases be created for removed commands pointing to official equivalents?

---

## References

- Issue: #78 - feat(claude): migrate custom commands to official Claude Code plugins
- Official Claude Code repository: <https://github.com/anthropics/claude-code>
- Claude Cookbooks repository: <https://github.com/anthropics/claude-cookbooks>
- Local configuration: `modules/home-manager/ai-cli/claude.nix`
- Plugin configuration: `modules/home-manager/ai-cli/claude-plugins.nix`
- Ecosystem documentation: `docs/ANTHROPIC-ECOSYSTEM.md`

---

## Appendix A: File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `modules/home-manager/ai-cli/claude.nix` | Modify | Remove `commit` from `aiInstructionsCommands` |
| `modules/home-manager/ai-cli/claude-plugins.nix` | Modify | Remove `review-pr-ci` from `cookbookCommands` |
| `docs/ANTHROPIC-ECOSYSTEM.md` | Modify | Update command counts and lists |
| `CLAUDE.md` | Modify | Update command references |
| `.ai-instructions/INSTRUCTIONS.md` | Modify | Update command table |

## Appendix B: Command Inventory Final State

### Official Plugin Commands (via plugins)

- `/commit` (commit-commands)
- `/commit-push-pr` (commit-commands)
- `/clean_gone` (commit-commands)
- `/code-review` (code-review)
- `/pr-review-toolkit:review-pr` (pr-review-toolkit)
- `/feature-dev` (feature-dev)
- `/plugin-dev:create-plugin` (plugin-dev)
- `/hookify` (hookify)
- `/new-sdk-app` (agent-sdk-dev)

### Cookbook Commands (retained)

- `/review-pr` (pending verification)
- `/review-issue`
- `/notebook-review`
- `/model-check`
- `/link-review`

### Custom Commands (retained)

- `/generate-code`
- `/git-refresh`
- `/infrastructure-review`
- `/pull-request`
- `/pull-request-review-feedback`
- `/review-code`
- `/review-docs`
- `/rok-resolve-issues`
- `/rok-respond-to-reviews`
- `/rok-review-pr`
- `/rok-shape-issues`

### Agent OS Commands (unchanged)

- `/create-tasks`
- `/implement-tasks`
- `/improve-skills`
- `/orchestrate-tasks`
- `/plan-product`
- `/shape-spec`
- `/write-spec`
