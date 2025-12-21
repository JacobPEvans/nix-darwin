# Claude Plugin Migration - Tasks

## Overview

This tasks list covers the migration from custom Claude commands to official Anthropic plugins,
managed declaratively via Nix. The migration removes redundant commands that now have official
equivalents while preserving unique custom functionality.

**Specification**: `agent-os/specs/claude-plugin-migration/spec.md`

**Key Changes**:

- Remove `commit` command (replaced by `commit-commands` plugin)
- Remove `review-pr-ci` cookbook command (replaced by `code-review` plugin)
- Remove `review-pr` cookbook command (replaced by `code-review` plugin)
- Update documentation to reflect changes

---

## Phase 1: Preparation and Backup

- [x] **1.1** Create backup directory: `mkdir -p ~/backups/claude-plugin-migration-$(date +%Y%m%d)`
- [x] **1.2** Backup `claude.nix`
- [x] **1.3** Backup `claude-plugins.nix`
- [x] **1.4** Backup Claude settings
- [x] **1.5** Record Nix generation number
- [x] **1.6** Create feature branch: `git checkout -b feat/claude-plugin-migration`

---

## Phase 2: Analysis and Validation

### 2.1 Analyze commit-commands Plugin

- [x] **2.1.1** Read custom `commit.md` command content
- [x] **2.1.2** Test official `/commit` command
- [x] **2.1.3** Document feature comparison
- [x] **2.1.4** Verify compliant commit messages
- [x] **2.1.5** Confirm `/commit-push-pr` workflow
- [x] **2.1.6** Decision: Approve removal

### 2.2 Analyze code-review Plugin

- [x] **2.2.1** Read `review-pr-ci` content
- [x] **2.2.2** Test `/code-review` plugin
- [x] **2.2.3** Document feature comparison
- [x] **2.2.4** Verify CI integration
- [x] **2.2.5** Decision: Approve removal

### 2.3 Analyze review-pr Command

- [x] **2.3.1** Read `review-pr` content
- [x] **2.3.2** Compare vs `/code-review`
- [x] **2.3.3** Identify unique features
- [x] **2.3.4** Decision: Remove (plugin provides coverage)
- [x] **2.3.5** Document rationale

### 2.4 Verify Retained Commands

- [x] **2.4.1** List retained commands (11)
- [x] **2.4.2** Verify no naming conflicts
- [x] **2.4.3** Confirm 4 cookbook commands retained
- [x] **2.4.4** Verify 7 Agent OS commands unchanged

---

## Phase 3: Configuration Changes

### 3.1 Update claude.nix

- [x] **3.1.1** Read `aiInstructionsCommands` list
- [x] **3.1.2** Remove `"commit"`
- [x] **3.1.3** Add migration comment
- [x] **3.1.4** Verify 11 commands remain
- [x] **3.1.5** Save changes

### 3.2 Update claude-plugins.nix

- [x] **3.2.1** Read `cookbookCommands` list
- [x] **3.2.2** Remove `"review-pr-ci"`
- [x] **3.2.3** Remove `"review-pr"`
- [x] **3.2.4** Add migration comment
- [x] **3.2.5** Verify 4 cookbook commands
- [x] **3.2.6** Verify 12 plugins enabled
- [x] **3.2.7** Save changes

### 3.3 Validate Configuration

- [x] **3.3.1** Run `nix flake check`
- [x] **3.3.2** Fix syntax errors
- [x] **3.3.3** Commit changes

---

## Phase 4: Build and Test

### 4.1 Apply Changes

- [ ] **4.1.1** Run `darwin-rebuild switch --flake .`
- [ ] **4.1.2** Verify rebuild succeeds
- [ ] **4.1.3** Fix errors if needed

### 4.2 Verify Official Plugin Commands

- [ ] **4.2.1** Run `/help` to verify commands
- [ ] **4.2.2** Test `/commit` command
- [ ] **4.2.3** Test `/code-review` command
- [ ] **4.2.4** Test `/commit-push-pr` workflow
- [ ] **4.2.5** Verify 12 plugins enabled

### 4.3 Verify Retained Custom Commands

- [ ] **4.3.1** Check symlinks: `ls -la ~/.claude/commands/`
- [ ] **4.3.2** Test `/manage-pr`
- [ ] **4.3.3** Test `/git-refresh`
- [ ] **4.3.4** Test `/review-code`
- [ ] **4.3.5** Test `/review-pr`
- [ ] **4.3.6** Confirm no orphaned symlinks

### 4.4 Verify Cookbook Commands

- [ ] **4.4.1** Verify `/review-issue`
- [ ] **4.4.2** Verify `/notebook-review`
- [ ] **4.4.3** Verify `/model-check`
- [ ] **4.4.4** Verify `/link-review`
- [ ] **4.4.5** Verify `/review-pr` absent

### 4.5 Regression Testing

- [ ] **4.5.1** Full dev cycle test
- [ ] **4.5.2** Verify no permission prompts
- [ ] **4.5.3** Verify CI triggers

---

## Phase 5: Documentation Updates

### 5.1 Update ANTHROPIC-ECOSYSTEM.md

- [x] **5.1.1** Read current file
- [x] **5.1.2** Remove `review-pr-ci` and `review-pr`
- [x] **5.1.3** Update command count (6→4)
- [x] **5.1.4** Add migration notes
- [x] **5.1.5** Update references
- [x] **5.1.6** Save changes

### 5.2 Update CLAUDE.md

- [x] **5.2.1** Read current file
- [x] **5.2.2** Update cookbook count
- [x] **5.2.3** Verify "4 cookbook commands"
- [x] **5.2.4** Save changes

### 5.3 Update INSTRUCTIONS.md

- [ ] **5.3.1** Check commit references
- [ ] **5.3.2** Update to `/commit` plugin
- [ ] **5.3.3** Update command tables

### 5.4 Add Migration Notes

- [x] **5.4.1** Create migration notes
- [x] **5.4.2** Document `/commit` usage
- [x] **5.4.3** Document `/code-review` usage
- [x] **5.4.4** Include rollback instructions

### 5.5 Commit Documentation

- [ ] **5.5.1** Stage changes
- [ ] **5.5.2** Commit with message

---

## Phase 6: Final Verification

### 6.1 Final Testing

- [ ] **6.1.1** End-to-end workflow test
- [ ] **6.1.2** Verify no regressions
- [ ] **6.1.3** Test rollback
- [ ] **6.1.4** Verify rollback works
- [ ] **6.1.5** Re-apply changes

### 6.2 Create Pull Request

- [ ] **6.2.1** Push branch
- [ ] **6.2.2** Create PR with summary
- [ ] **6.2.3** Reference issue #78
- [ ] **6.2.4** Include test evidence

### 6.3 Post-Merge Cleanup

- [ ] **6.3.1** Delete feature branch
- [ ] **6.3.2** Update CHANGELOG.md
- [ ] **6.3.3** Archive backups (30 days)
- [ ] **6.3.4** Close issue #78

---

## Rollback Procedures

**Immediate**: `darwin-rebuild switch --rollback`

**Git**: `git revert HEAD --no-edit && darwin-rebuild switch --flake .`

**Full Recovery**: Restore from ~/backups/claude-plugin-migration-*/

---

## Success Criteria

**Must Have**:

- [ ] 12 official plugins functional
- [x] Commands removed from config
- [x] `nix flake check` passes
- [ ] `darwin-rebuild switch` succeeds
- [ ] Official plugins work
- [ ] Retained commands function
- [ ] No orphaned symlinks

**Should Have**:

- [x] Documentation updated
- [x] Migration notes added
- [ ] No user confusion
- [ ] No regressions
