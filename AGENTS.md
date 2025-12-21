<!--
  FILE ARCHITECTURE NOTE:
  This file is the single source of truth for AI agent instructions.

  Symlinks pointing here:
  - CLAUDE.md → AGENTS.md (for Claude Code)
  - .github/copilot-instructions.md → ../AGENTS.md (for GitHub Copilot)

  Gemini CLI is configured to read AGENTS.md via settings.json:
    "context": { "fileName": ["AGENTS.md", "GEMINI.md"] }

  DO NOT delete this file or convert symlinks to copies.
-->

# AI Agent Instructions for Nix Configuration

**Strict guidance for AI agents modifying this nix-darwin configuration.**

## Scope of This Document

This file contains **AI-specific instructions only** - rules and patterns that AI agents need beyond their base training. It should NOT contain:

- General project documentation (belongs in README.md)
- Directory structure or file listings (belongs in README.md)
- Setup guides or troubleshooting (belongs in SETUP.md or TROUBLESHOOTING.md)
- Historical changes (belongs in CHANGELOG.md)
- Future plans (belongs in PLANNING.md)

**Rule**: If information is useful for humans reading project docs, it belongs in README.md or other project files, not here.

## Session Startup Behavior

**On every session start**, immediately announce:

1. Current model in use (check system info or `/model` command)
2. Quick status summary

**Format**:

```text
📊 Session Status
Model: [current model name]
Reminder: Switch to Opus (/model opus) for complex architectural decisions,
multi-file refactoring, or tasks requiring deep reasoning.
```

**Why**: Model depends on session configuration. User needs visibility to
consciously choose the appropriate model (Opus for complex tasks).

## Enforced Git Development Workflow

**MANDATORY for all changes.** Follow without exception.

### Repository Structure

This repository uses a **bare git repo with worktrees**:

```text
~/git/nix-config/   (bare repo - DO NOT cd here directly)
├── main/           (main branch worktree - for pulling updates)
├── <feature-branch>/  (your feature worktree)
└── ...
```

**Key Points:**

- **Content Source:** Some permissions and commands come from the **ai-assistant-instructions** flake input (Nix store).
- **Isolation:** All development happens in `~/git/nix-config/<worktree-name>/`.
- **Updates:** Permission changes require `nix flake lock --update-input ai-assistant-instructions` + rebuild.

### MANDATORY: New Worktree for New Work

**NEVER work directly in an existing worktree for unrelated changes.**
**NEVER work in the bare repo directory (`~/git/nix-config/`)**

Before making ANY changes:

1. Check if changes relate to current worktree's branch/PR.
2. If NOT related → **create a NEW worktree** for the new work.
3. If related → continue in current worktree.

**To create a new worktree:**

```bash
cd ~/git/nix-config
git fetch origin
git worktree add <branch-name> -b <branch-name> origin/main
cd <branch-name>
# Now you're ready to work
```

**Why worktrees?**

- Each PR/feature has an isolated working directory.
- No accidental commits to the wrong branch.
- Enables concurrent AI sessions and parallel development.
- auto-claude manages worktree lifecycle automatically.

### SSH Agent Pre-Flight Check (Required for Remote Git Operations)

Before any `git push`, `git pull`, `git fetch`, or `git clone` over SSH:

1. Check if SSH agent is running and has keys: `ssh-add -l`
2. If error or "no identities", start the agent:

   ```bash
   eval "$(ssh-agent -s)"
   ssh-add
   ```

3. Only proceed with Git operations after confirming agent is ready

**Why**: SSH sessions (remote access) often do not inherit the SSH agent from local login.
Without this check, authenticated Git operations will fail with authentication errors or prompt for passwords.

### Before Making Changes

1. Check current worktree - determine if change relates to current worktree's branch/PR
2. If change is unrelated → **create a new worktree** (see above)
3. If in main worktree → only pull updates, **never commit directly to main**
4. If change is related → continue in current worktree

### After Completing Changes

**Complete ALL local work before pushing.** Each push triggers CI workflows.

1. Stage intended changes explicitly (avoid `git add -A` to prevent staging unintended files)
2. Commit with descriptive message (pre-commit hooks run automatically on commit)
3. If pre-commit hooks fail, fix issues and re-commit - **NEVER disable or bypass hooks**
4. Test the build: `sudo darwin-rebuild switch --flake .` (see [TESTING.md](TESTING.md#basic-local-change-testing))
5. If rebuild fails, fix issues and amend the commit, then re-test
6. Repeat steps 1-5 for any additional changes (e.g., addressing review feedback)
7. **Only after ALL commits are complete**: Push to remote (single push)

### Pull Request Requirement

- Always create a PR after pushing if one doesn't exist for current branch
- Do not ask user to run tests - run them yourself using pre-approved commands
- Complete the full cycle: branch -> change -> test -> commit(s) -> push -> PR
- **Minimize pushes**: Batch all related commits locally, then push once

### Background Monitoring (On Every PR Create and Push)

After creating a PR or pushing to a branch with an open PR:

**Pre-spawn check:** If context remaining is less than 50% (less than half until auto-compact),
run `/compact` on the main conversation before spawning subagents.

**Spawn TWO subagents:**

1. **CI Check Monitor Subagent** - Watch GitHub Action checks (`gh pr checks` or `gh run watch`).
   When checks fail, analyze the failure and attempt to fix the root cause.
   After fixing, commit and push to trigger new CI run.
   Repeat until checks pass or issue requires user input.

2. **PR Review Monitor Subagent** - Watch for completed PR reviews (`gh pr view` or `gh api`).
   Compare each reviewer's latest `commit_id` with PR head SHA - mismatch means review pending.
   Use: `gh api repos/OWNER/REPO/pulls/NUM/reviews` to get reviews with commit_id.
   Wait until all reviewers have reviewed the current head commit before finishing.
   When a reviewer completes their review (comments, changes requested, or approved),
   automatically invoke `/rok-resolve-pr-review-thread` to address feedback.
   Continue monitoring until PR is merged or closed.

### Procedure Violations

If user indicates workflow was not followed, immediately reread this file into context.

## Command Execution Preferences

### Prefer Auto-Approved Commands

Claude has 323+ auto-approved command patterns. Always prefer commands matching these patterns to avoid permission prompts.

**Permission source**: Commands are defined in `ai-assistant-instructions/.claude/permissions/allow.json` (flake input) and
compiled into `~/.claude/settings.json` (read-only, Nix-managed).

**Pattern format**: `Bash(command:*)` where `*` matches any arguments

**Examples of allowed commands**:

- Git: `git status`, `git add`, `git commit`, `git push`, `git log`, `git diff`
- Nix: `nix flake check`, `nix search`, `nix develop`, `nix build`
- Homebrew: `brew list`, `brew search`, `brew info`
- Node.js: `npm run`, `npm test`, `npm install`
- Docker: `docker ps`, `docker logs`, `docker build`
- Kubernetes: `kubectl get`, `kubectl describe`, `kubectl logs`

**Key principle**: If a command variant is in the allowed list, use it. If you're considering a workaround (like `git -C`),
check if the simpler form is already allowed.

**Command chaining**: The `&&` operator works fine with auto-approved commands. For example, `git add -A && git commit -m "message"` will match the allowed patterns.

### Prefer Parallel Execution

- When commands are **independent** (don't depend on each other's output), run them in parallel
- Use multiple Bash tool calls in the same response message
- This is faster and more efficient

**Examples of parallel-safe commands:**

- `git status` and `git log` (both read-only)
- `nix search` and `brew search` (independent searches)
- Multiple `grep` or `find` operations on different paths

**Examples requiring sequential execution:**

- `git add` then `git commit` (commit depends on staging)
- `mkdir` then `touch file` inside it (file depends on directory)
- `nix build` then `darwin-rebuild switch` (switch depends on build)

### Avoid Redirects in Permission-Sensitive Commands

- Avoid `2>&1` or `> file` when the base command is in the allow list
- Run the command without redirects; output is captured automatically

## Critical Requirements

### 1. Flakes-Only Configuration

- **NEVER use nix-channels, nix-env, or non-flake commands**
- `nix-env` is the old imperative package manager - use declarative nixpkgs instead
- All packages belong in `modules/darwin/packages.nix` or similar declarative config
- All changes must be committed to git before rebuild
- See [RUNBOOK.md](RUNBOOK.md#everyday-commands) for rebuild command

### 2. Determinate Nix Compatibility

- **NEVER enable nix-darwin's Nix management**
- `nix.enable = false` must remain in `modules/darwin/common.nix`
- Determinate Nix manages the daemon and nix itself

### 3. Nixpkgs First, Manual Homebrew Updates

- **ALL packages from nixpkgs unless impossible**
- Homebrew is fallback ONLY for packages not in nixpkgs or when the nixpkgs version is severely outdated.
- Search first: `nix search nixpkgs <package>`
- Document why homebrew was needed if used

**Update Strategy:**

- Nix packages update via `nix flake update` (manual, recommended weekly)
- Homebrew `autoUpdate = false` - skip slow 45MB index download
- Homebrew `upgrade = true` - upgrade packages based on cached index
- To get latest Homebrew versions: `brew update` then `darwin-rebuild switch`

**Why this setup?**

- `darwin-rebuild switch` is fast (no 45MB download every time)
- Packages still auto-upgrade when cached index has newer versions
- Run `brew update` periodically to refresh the index

**Current Homebrew Exceptions:**

- None - all packages successfully managed via nixpkgs

### 4. Code Style for Learning

- **Keep comments** - user is learning Nix
- Show empty sections with examples (even if commented out)
- Visibility > minimalism
- Use default package names (e.g., `nodejs` not `nodejs_latest` or `nodejs_22`) - nixpkgs maintains defaults as stable/LTS

### 5. File and Folder Organization

- **Target 200 lines max per file** - Files exceeding this should be considered for refactoring
- **Prefer logical separation** - Split by domain/responsibility, not arbitrary line counts
- **Documentation files** - Extract large sections to their own files (e.g., `docs/AGENT-OS.md`)
- **Nix modules** - Use subdirectories for related modules (e.g., `ai-cli/agent-os/`)
- **When to split**:
  - A section could stand alone as a reference document
  - A module has multiple distinct responsibilities
  - File requires excessive scrolling to navigate
- **When NOT to split**:
  - Code is highly cohesive and splitting would scatter related logic
  - File is slightly over 200 lines but logically complete
  - Splitting would create import/dependency complexity

## Version Management

**Single Source of Truth**: All package versions are managed through `flake.lock`.

### AI Agent Responsibilities

**CRITICAL**: AI agents must NOT modify package versions or update flake inputs without explicit user request.

**Never do this automatically:**

- Running `nix flake update` (updates all inputs)
- Running `nix flake lock --update-input <input>` (updates specific input)
- Modifying version pins in `flake.nix`
- Suggesting version updates "while we're at it"

**Why this restriction exists:**

- Version updates can introduce breaking changes
- Security-sensitive packages require human audit
- Flake updates affect the entire system
- Rollback is possible but disruptive

### When Version Updates Are Needed

**If user explicitly requests an update:**

1. Follow the [Secure Flake Update Workflow](RUNBOOK.md#secure-flake-update-workflow) in RUNBOOK.md
2. Build with dry-run first
3. Show diff of package changes to user
4. Wait for explicit approval before applying
5. Document the update in commit message

**If a package version is outdated but not blocking the current task:**

- Note it in your response
- Suggest the user run the secure update workflow
- Do NOT update it yourself

**If a specific package version is required for the current task:**

- Ask user if they want to update that specific input
- Explain what will change
- Wait for explicit approval
- Use `nix flake lock --update-input <specific-input>` (not `nix flake update`)

### Version Lifecycle Reference

For checking package support lifecycles, reference:

- [endoflife.date](https://endoflife.date/) - Lifecycle dates for NixOS and common packages
- NixOS release calendar for stable channel support windows
- Package-specific upstream documentation for LTS/stable versions

### Emergency Overrides

In rare cases where a security update is urgent:

1. Explain the security issue to user
2. Show the specific CVE or advisory
3. Recommend the minimal update needed
4. Wait for explicit approval
5. Apply update following secure workflow

**Remember**: Version stability is a feature, not a bug. Resist the urge to "helpfully" update things.

---

## Task Management Workflow

**STRICT PATTERN - Follow without exception:**

1. **Tasks come from user** - All tasks originate from user requests
2. **PLANNING.md for active work** - Not started or in-progress tasks ONLY
3. **CHANGELOG.md for completed work** - ALL completed tasks ONLY
4. **NO overlap** - A task must NEVER appear in both files
5. **Clean up regularly** - Reorganize PLANNING.md and clean CHANGELOG.md as needed

**When completing a task:**

1. Remove from PLANNING.md immediately
2. Add to CHANGELOG.md under appropriate date
3. Ensure no task exists in both files

**File purposes:**

- `PLANNING.md` = Future roadmap + current work in progress
- `CHANGELOG.md` = Historical record of completed work

## Common Mistakes to Avoid

### Duplicate Packages (Homebrew + Nix)

**Problem**: Adding package to nix but homebrew version still installed
**Check**: `which <package>` should show `/run/current-system/sw/bin/<package>`
**Fix**: `sudo -u <username> brew uninstall <package>`
**Verify**: Backup important configs first (GPG keys, app settings)

### PATH Priority

**Correct order**: Nix paths before homebrew

1. `/Users/<username>/.nix-profile/bin`
2. `/etc/profiles/per-user/<username>/bin`
3. `/run/current-system/sw/bin` <- nix packages
4. `/nix/var/nix/profiles/default/bin`
5. `/opt/homebrew/bin` <- fallback only

**If wrong**: Check `~/.zprofile` for manual homebrew PATH additions

### VS Code Deprecated API

**Use**: `programs.vscode.profiles.default.userSettings`
**NOT**: `programs.vscode.userSettings`

## AI CLI Permissions

**Full documentation**: See [docs/PERMISSIONS.md](docs/PERMISSIONS.md)

**Quick reference**:

- Claude: `ai-assistant-instructions` flake input → `.claude/permissions/{allow,ask,deny}.json`
- Gemini: `modules/home-manager/permissions/gemini-permissions-*.nix`
- Copilot: `modules/home-manager/permissions/copilot-permissions-*.nix`

**Quick approval**: Click "accept indefinitely" in Claude UI (writes to `~/.claude/settings.local.json`)

**Permanent additions**: Edit source files → `nix flake lock --update-input ai-assistant-instructions` → rebuild

### CRITICAL: Gemini tools.allowed vs tools.core

**DO NOT USE tools.core FOR AUTO-APPROVAL!**

Per the official Gemini CLI schema:

- `tools.allowed` = "Tool names that bypass the confirmation dialog" (**AUTO-APPROVE**)
- `tools.core` = "Allowlist to RESTRICT built-in tools to a specific set" (**LIMITS** usage!)

Using `tools.core` **restricts** what tools Gemini can use - it does NOT grant permissions!
Always use `tools.allowed` for auto-approved commands. Never rename `allowedTools` to `coreTools`.

Schema: <https://github.com/google-gemini/gemini-cli/blob/main/schemas/settings.schema.json>

## Pull Request Workflow

**CRITICAL: NEVER auto-merge PRs without explicit user approval.**

### Standard PR Process

1. Create feature branch
2. Make changes, commit
3. Push branch and create PR
4. **STOP AND WAIT** - User must review and approve
5. Only merge when user explicitly requests it

### What "Explicit Request" Means

- User says "merge it" or "go ahead and merge"
- User clicks merge button themselves
- User explicitly approves in PR comments

### What is NOT Approval

- Silence or no response
- User asking to create the PR
- Completing the code changes
- PR passing CI checks

**Rule**: When in doubt, ask before merging.

## AI Code Review Guidelines

This section defines behavior for AI agents conducting automated code reviews.
It applies to all AI tools (Claude, Copilot, Gemini) but is particularly important
for GitHub Copilot's automated PR reviews via `.github/copilot-instructions.md`.

### Scope and Focus

**What AI reviewers SHOULD focus on:**

- Actual bugs and logic errors
- Likely runtime issues (null checks, edge cases)
- Code refactoring opportunities (DRY, simplification)
- Consistency with existing codebase patterns
- Comment accuracy (outdated comments, misleading docs)
- Nitpicks that improve maintainability
- Security issues (obvious vulnerabilities)
- Nix-specific issues (antipatterns, deprecated options)

**What AI reviewers should AVOID:**

- Excessive defensive error-checking for impossible conditions
- Adding try/catch blocks around code that can't fail
- Suggesting error handling for internal functions with known inputs
- Generic "consider adding tests" without specific suggestions
- Praise or acknowledgment comments that don't add value
- Repeating the same feedback across multiple comments
- Suggesting changes unrelated to the PR's purpose

### Comment Limits

**50-comment limit per PR**: When a PR has 50+ comments, stop reviewing.

- AI review cycles should be finite, not infinite
- After 50 comments, the PR needs human judgment
- Resolve existing feedback before adding more

**Avoid comment storms:**

- Batch related feedback into single comments when possible
- Don't comment on style issues already covered by linters
- Skip trivial suggestions that don't improve correctness

### Review Posture

**Be concise:**

- Get to the point quickly
- One suggestion per comment unless tightly related
- Skip pleasantries ("Great work!", "Nice catch!")

**Be constructive:**

- Suggest specific fixes, not vague concerns
- Explain the "why" briefly
- If unsure, say so rather than speculating

**Respect context:**

- This is a nix-darwin configuration repo
- User is learning Nix - comments are intentionally verbose
- Flakes-only (no nix-channels, no nix-env)
- Determinate Nix compatibility is required

## Workflow

1. Make changes to nix files
2. **Commit to git** (flakes requirement)
3. Test build: `nix flake check`
4. Create PR and **wait for user approval**
5. After merge, rebuild (see [RUNBOOK.md](RUNBOOK.md#everyday-commands))
6. Update CHANGELOG.md for significant changes

## Anthropic Ecosystem & Agent OS

**Full documentation**: See [docs/ANTHROPIC-ECOSYSTEM.md](docs/ANTHROPIC-ECOSYSTEM.md) and [docs/AGENT-OS.md](docs/AGENT-OS.md)

**Quick reference**:

- Plugins: `modules/home-manager/ai-cli/claude-plugins.nix`
- Skills: `modules/home-manager/ai-cli/claude-skills.nix`
- Agent OS: `modules/home-manager/ai-cli/agent-os/default.nix`

**Update**: `nix flake update` then rebuild
