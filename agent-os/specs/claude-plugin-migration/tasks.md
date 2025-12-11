# Claude Plugin Migration - Tasks

## Overview

This tasks list covers the migration from custom Claude commands to official Anthropic plugins,
managed declaratively via Nix. The migration removes redundant commands that now have official
equivalents while preserving unique custom functionality.

**Specification**: `/Users/jevans/.config/nix/agent-os/specs/claude-plugin-migration/spec.md`

**Key Changes**:

- Remove `commit` command (replaced by `commit-commands` plugin)
- Remove `review-pr-ci` cookbook command (replaced by `code-review` plugin)
- Verify `review-pr` cookbook command status
- Update documentation to reflect changes

---

## Phase 1: Preparation and Backup

**Objective**: Create safety net before making any changes

- [x] **1.1** Create backup directory:
  `mkdir -p ~/backups/claude-plugin-migration-$(date +%Y%m%d)`
- [x] **1.2** Backup `claude.nix`:
  `cp ~/.config/nix/modules/home-manager/ai-cli/claude.nix ~/backups/claude-plugin-migration-*/`
- [x] **1.3** Backup `claude-plugins.nix`:
  `cp ~/.config/nix/modules/home-manager/ai-cli/claude-plugins.nix ~/backups/claude-plugin-migration-*/`
- [x] **1.4** Backup current Claude settings:
  `cp ~/.claude/settings.json ~/backups/claude-plugin-migration-*/settings.json.backup`
- [x] **1.5** Record current Nix generation number:
  `darwin-rebuild switch --list-generations | tail -1 > ~/backups/claude-plugin-migration-*/generation.txt`
- [x] **1.6** Create feature branch: `git checkout -b feat/claude-plugin-migration`

---

## Phase 2: Analysis and Validation

**Objective**: Verify official plugins provide equivalent functionality before removing custom commands

### 2.1 Analyze commit-commands Plugin

- [x] **2.1.1** Read current custom `commit.md` command content from ai-assistant-instructions repository
- [x] **2.1.2** Test official `/commit` command from `commit-commands` plugin on a test change
- [x] **2.1.3** Document feature comparison: custom commit vs official /commit
- [x] **2.1.4** Verify official `/commit` produces compliant commit messages
- [x] **2.1.5** Confirm `/commit-push-pr` workflow functions correctly (bonus feature)
- [x] **2.1.6** Decision: Approve removal of custom `commit` command if feature parity confirmed

### 2.2 Analyze code-review Plugin

- [x] **2.2.1** Read current `review-pr-ci` cookbook command content
- [x] **2.2.2** Test official `/code-review` plugin on an existing PR
- [x] **2.2.3** Document feature comparison: `review-pr-ci` vs `/code-review`
- [x] **2.2.4** Verify CI integration capabilities of official plugin
- [x] **2.2.5** Decision: Approve removal of `review-pr-ci` if feature parity confirmed

### 2.3 Analyze review-pr Cookbook Command (Open Question)

- [x] **2.3.1** Read `review-pr` cookbook command content
- [x] **2.3.2** Compare `review-pr` (interactive) vs `/code-review` plugin functionality
- [x] **2.3.3** Identify any unique features in `review-pr` not in `/code-review`
- [x] **2.3.4** Decision: Keep or remove `review-pr` based on analysis
- [x] **2.3.5** Document decision rationale in spec or migration notes

### 2.4 Verify Retained Commands

- [x] **2.4.1** List all custom commands that will be retained (11 commands)
- [x] **2.4.2** Verify no naming conflicts between retained custom commands and official plugins
- [x] **2.4.3** Confirm all 5 retained cookbook commands have no official equivalent
- [x] **2.4.4** Verify all 7 Agent OS commands remain unchanged

---

## Phase 3: Configuration Changes

**Objective**: Update Nix configuration files to remove redundant commands

**Dependency**: Phase 2 complete - Decisions finalized:

- REMOVE: `commit` from aiInstructionsCommands (replaced by /commit plugin)
- REMOVE: `review-pr-ci` from cookbookCommands (replaced by /code-review plugin)
- KEEP: `review-pr` in cookbookCommands (provides unique interactive safeguards)

### 3.1 Update claude.nix

- [x] **3.1.1** Read current `aiInstructionsCommands` list in claude.nix
- [x] **3.1.2** Remove `"commit"` from `aiInstructionsCommands` list
- [x] **3.1.3** Add comment documenting migration:
  `# Removed: "commit" - replaced by commit-commands plugin (/commit)`
- [x] **3.1.4** Verify remaining 11 custom commands are present and correctly listed
- [x] **3.1.5** Save changes to `claude.nix`

### 3.2 Update claude-plugins.nix

- [x] **3.2.1** Read current `cookbookCommands` list in claude-plugins.nix
- [x] **3.2.2** Remove `"review-pr-ci"` from `cookbookCommands` list
- [x] **3.2.3** KEEP `"review-pr"` (Phase 2 decision: provides unique interactive value)
- [x] **3.2.4** Add comment documenting migration:
  `# Removed: "review-pr-ci" - replaced by code-review plugin (/code-review)`
- [x] **3.2.5** Verify retained cookbook commands are present
  (5 commands: review-pr, review-issue, notebook-review, model-check, link-review)
- [x] **3.2.6** Verify all 12 official plugins remain in `enabledPlugins` list
- [x] **3.2.7** Save changes to `claude-plugins.nix`

### 3.3 Validate Configuration

- [x] **3.3.1** Run `nix flake check` in `/Users/jevans/.config/nix`
- [x] **3.3.2** Fix any Nix syntax errors if check fails
- [x] **3.3.3** Commit configuration changes with descriptive message

---

## Phase 4: Build and Test

**Objective**: Apply changes and verify all functionality works correctly

**Dependency**: Phase 3 must be complete (configuration valid)

### 4.1 Apply Changes

- [ ] **4.1.1** Run `sudo darwin-rebuild switch --flake /Users/jevans/.config/nix`
- [ ] **4.1.2** Verify rebuild completes without errors
- [ ] **4.1.3** If rebuild fails, analyze error and fix (return to Phase 3 if config issue)

### 4.2 Verify Official Plugin Commands

- [ ] **4.2.1** Run `/help` in Claude Code to verify command listing
- [ ] **4.2.2** Test `/commit` command on a test change
- [ ] **4.2.3** Test `/code-review` command on a test PR
- [ ] **4.2.4** Test `/commit-push-pr` command (end-to-end workflow)
- [ ] **4.2.5** Verify all 12 official plugins show as enabled:
  `jq '.enabledPlugins' ~/.claude/settings.json`

### 4.3 Verify Retained Custom Commands

- [ ] **4.3.1** Verify custom commands are symlinked: `ls -la ~/.claude/commands/`
- [ ] **4.3.2** Test `/pull-request` command
- [ ] **4.3.3** Test `/git-refresh` command
- [ ] **4.3.4** Test `/review-code` command
- [ ] **4.3.5** Test `/rok-review-pr` command (representative ROK command)
- [ ] **4.3.6** Confirm no orphaned symlinks for removed commands

### 4.4 Verify Retained Cookbook Commands

- [ ] **4.4.1** Verify `/review-issue` command is available
- [ ] **4.4.2** Verify `/notebook-review` command is available
- [ ] **4.4.3** Verify `/model-check` command is available
- [ ] **4.4.4** Verify `/link-review` command is available
- [ ] **4.4.5** Verify `/review-pr` is present or absent based on Phase 2 decision

### 4.5 Regression Testing

- [ ] **4.5.1** Full development cycle test: create branch, make change, commit, create PR
- [ ] **4.5.2** Verify no permission prompts for pre-approved commands
- [ ] **4.5.3** Verify CI workflow triggers correctly on push

---

## Phase 5: Documentation Updates

**Objective**: Update all documentation to reflect new command structure

**Dependency**: Phase 4 must be complete (functionality verified)

### 5.1 Update ANTHROPIC-ECOSYSTEM.md

- [ ] **5.1.1** Read current `/Users/jevans/.config/nix/docs/ANTHROPIC-ECOSYSTEM.md`
- [ ] **5.1.2** Update "Cookbook Commands" section to remove `review-pr-ci`
- [ ] **5.1.3** Update command count (from 6 to 5, or 4 if review-pr also removed)
- [ ] **5.1.4** Add migration notes section explaining command changes
- [ ] **5.1.5** Update any references to removed commands
- [ ] **5.1.6** Save changes to `ANTHROPIC-ECOSYSTEM.md`

### 5.2 Update CLAUDE.md

- [ ] **5.2.1** Read current `/Users/jevans/.config/nix/CLAUDE.md`
- [ ] **5.2.2** Update "Anthropic Ecosystem Integration" section if it references removed commands
- [ ] **5.2.3** Verify cookbook command count reference is updated
- [ ] **5.2.4** Save changes to `CLAUDE.md`

### 5.3 Update .ai-instructions/INSTRUCTIONS.md (if applicable)

- [ ] **5.3.1** Check if INSTRUCTIONS.md references the removed `commit` command
- [ ] **5.3.2** Update any references to use `/commit` from official plugin
- [ ] **5.3.3** Update command tables if they list custom commands

### 5.4 Add Migration Notes

- [ ] **5.4.1** Create or update migration notes for users of removed commands
- [ ] **5.4.2** Document: "Use `/commit` instead of custom `commit` command"
- [ ] **5.4.3** Document: "Use `/code-review` instead of `review-pr-ci`"
- [ ] **5.4.4** Include rollback instructions in documentation

### 5.5 Commit Documentation Changes

- [ ] **5.5.1** Stage all documentation changes
- [ ] **5.5.2** Commit with descriptive message: "docs: update command references for plugin migration"

---

## Phase 6: Final Verification and Completion

**Objective**: Complete testing, create PR, and close out migration

**Dependency**: Phase 5 must be complete (documentation updated)

### 6.1 Final Testing

- [ ] **6.1.1** Run complete end-to-end development workflow test
- [ ] **6.1.2** Verify no regressions in daily usage patterns
- [ ] **6.1.3** Test rollback procedure: `darwin-rebuild switch --rollback`
- [ ] **6.1.4** Verify rollback restores previous configuration
- [ ] **6.1.5** Re-apply changes: `darwin-rebuild switch --flake /Users/jevans/.config/nix`

### 6.2 Create Pull Request

- [ ] **6.2.1** Push feature branch to remote: `git push -u origin feat/claude-plugin-migration`
- [ ] **6.2.2** Create PR with summary of changes and test results
- [ ] **6.2.3** Reference issue #78 in PR description
- [ ] **6.2.4** Include test evidence (screenshots or logs) in PR

### 6.3 Post-Merge Cleanup

- [ ] **6.3.1** After PR approval and merge, delete feature branch
- [ ] **6.3.2** Update CHANGELOG.md with migration completion
- [ ] **6.3.3** Archive backup files (keep for 30 days)
- [ ] **6.3.4** Close issue #78

---

## Rollback Procedures

### Immediate Rollback (if issues found during Phase 4)

```bash
# Revert to previous Nix generation
darwin-rebuild switch --rollback
```

### Git Rollback (if issues found after commit)

```bash
# Revert the migration commit
git revert HEAD --no-edit
darwin-rebuild switch --flake /Users/jevans/.config/nix
```

### Full Recovery (if above methods fail)

```bash
# Restore from backup
cp ~/backups/claude-plugin-migration-*/claude.nix.backup \
   /Users/jevans/.config/nix/modules/home-manager/ai-cli/claude.nix
cp ~/backups/claude-plugin-migration-*/claude-plugins.nix.backup \
   /Users/jevans/.config/nix/modules/home-manager/ai-cli/claude-plugins.nix
git add -A
git commit -m "chore: rollback plugin migration"
darwin-rebuild switch --flake /Users/jevans/.config/nix
```

---

## Success Criteria Checklist

### Must Have (Migration cannot be considered complete without these)

- [ ] All 12 official plugins enabled and functional
- [x] `commit` command removed from `aiInstructionsCommands`
- [x] `review-pr-ci` removed from `cookbookCommands`
- [x] `nix flake check` passes
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

## Open Questions to Resolve

1. **`review-pr` status**: Does the interactive `review-pr` cookbook command provide unique value
   over `/code-review` plugin? (Resolve in Phase 2.3)

2. **Plugin command prefixes**: Confirm whether official plugin commands use prefixes
   (e.g., `/commit-commands:commit`) or short names (e.g., `/commit`)

3. **Feature flags**: Should removed commands be gated behind a feature flag during initial rollout?

4. **Backwards compatibility**: Should aliases be created for removed commands pointing to
   official equivalents?

---

## Files to Modify

| File | Phase | Change Type |
|------|-------|-------------|
| `modules/home-manager/ai-cli/claude.nix` | 3.1 | Remove `commit` from list |
| `modules/home-manager/ai-cli/claude-plugins.nix` | 3.2 | Remove `review-pr-ci` from list |
| `docs/ANTHROPIC-ECOSYSTEM.md` | 5.1 | Update command counts and lists |
| `CLAUDE.md` | 5.2 | Update command references |
| `.ai-instructions/INSTRUCTIONS.md` | 5.3 | Update command table (if applicable) |

---

## Estimated Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Preparation | 15 minutes | None |
| Phase 2: Analysis | 1-2 hours | Phase 1 |
| Phase 3: Configuration | 30 minutes | Phase 2 |
| Phase 4: Build and Test | 1 hour | Phase 3 |
| Phase 5: Documentation | 30 minutes | Phase 4 |
| Phase 6: Final Verification | 1 hour | Phase 5 |

**Total Estimated Time**: 4-5 hours

---

## Notes

- All file paths are absolute as required by the project conventions
- Tasks are ordered to minimize risk and maximize rollback capability
- Each phase has explicit dependencies to ensure correct execution order
- Backup tasks are mandatory before any configuration changes
- Testing is comprehensive to catch regressions early
