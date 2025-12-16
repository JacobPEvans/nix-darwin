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

**Why**: Default model is Sonnet for cost efficiency. User needs visibility to
consciously choose Opus when the task warrants it.

## Enforced Git Development Workflow

**MANDATORY for all changes.** Follow without exception.

### Worktree-Based Development (Required for ai-assistant-instructions)

The `ai-assistant-instructions` repository uses git worktrees for branch isolation:

- **Main branch**: `~/git/ai-assistant-instructions/main/`
- **Feature branches**: `~/git/ai-assistant-instructions/<branch-name>/`

**All changes MUST be made on a dedicated worktree/branch** - never edit `main` directly.
This enables concurrent AI sessions and parallel development on separate features.

```bash
# Create new worktree for a feature
cd ~/git/ai-assistant-instructions/main
git worktree add ../my-feature -b feat/my-feature
cd ../my-feature
```

**Content source**: Permissions, commands, and instruction files come from the **Nix store**
(flake input), not the local repo. The local repo is only used by autoClaude for autonomous
commits. Changes require `nix flake lock --update-input ai-assistant-instructions` + rebuild.

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

1. Check current branch - determine if change relates to current worktree+branch
2. If on `main`: create new feature branch before modifying any files
3. If on unrelated branch: switch to main, pull latest, create new dedicated branch
4. Never make changes directly on `main`

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
   automatically invoke `/rok-respond-to-reviews` to address feedback.
   Continue monitoring until PR is merged or closed.

### Procedure Violations

If user indicates workflow was not followed, immediately reread this file into context.

## Command Execution Preferences

### Avoid Command Chaining with &&

- **NEVER chain commands with `&&`** - permission patterns don't match compound commands
- Run each command separately in its own Bash tool call
- This ensures each command matches its permission pattern correctly

**Bad:**

```bash
git add -A && git commit -m "message"
```

**Good:** (two separate tool calls)

```bash
git add -A
```

```bash
git commit -m "message"
```

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

## Claude Code Permission Management

**Layered Strategy**: Nix manages baseline, settings.local.json for ad-hoc approvals

**Permission files** (`modules/home-manager/permissions/`):

- `claude-permissions-allow.nix` - Auto-approved commands (280+ in 25 categories)
- `claude-permissions-ask.nix` - Commands requiring user confirmation
- `claude-permissions-deny.nix` - Permanently blocked (catastrophic operations)

**User-managed** (`~/.claude/settings.local.json`):

- NOT managed by Nix (intentionally writable)
- Claude writes here on "accept indefinitely"
- Machine-local only

**Directory Access** (`additionalDirectories`):

- Configured in `modules/home-manager/ai-cli/claude.nix`
- Grants Claude read access to directories outside working directory
- Prevents "allow reading from X/" prompts
- Default: `~/`, `~/.claude/`, `~/.config/`

**To add commands permanently**:

1. Edit appropriate file in `modules/home-manager/permissions/`
2. Add to appropriate category (allow, ask, or deny)
3. Commit and rebuild

**For quick approval**: Just click "accept indefinitely" in Claude UI

### Debugging Permission Issues

**Common causes of broken permissions**:

1. **Project-level overrides**: `settings.local.json` in project `.claude/` directories
   OVERRIDE (not merge with) global permissions
   - Check: `ls ./.claude/settings.local.json`
   - Fix: Delete or edit the file to remove `"allow": []` which clears all permissions

2. **Stale settings**: Source permissions changed but `darwin-rebuild switch` not run
   - Check: Compare `~/.claude/settings.json` permission count vs source JSON
   - Fix: Run `darwin-rebuild switch` to regenerate

3. **Invalid permission patterns**: Wildcards must follow strict format
   - Rule: Bash commands must end with `:*` (e.g., `Bash(git status:*)`)
   - Rule: Only 0 or 1 wildcards per pattern, none in the middle
   - Valid: `Bash(git log:*)`, `Read(**)`
   - Invalid: `Bash(git * status:*)`, `Bash(npm run:*:*)`

**Verification steps**:

```bash
# Count permissions in deployed settings (from Nix store flake input)
jq '.permissions.allow | length' ~/.claude/settings.json

# Check for project-level overrides in current directory
cat ./.claude/settings.local.json 2>/dev/null | jq '.allow | length'

# To check source permissions, view the flake input or local dev repo:
# jq '.permissions | length' ~/git/ai-assistant-instructions/main/.claude/permissions/allow.json
```

**Note**: After fixing permissions, restart Claude Code for changes to take effect.

## Gemini CLI Permission Management

**Strategy**: Nix-managed configuration using coreTools and excludeTools

**Configuration location**: `~/.gemini/settings.json`

**Permission files** (`modules/home-manager/permissions/`):

- `gemini-permissions-allow.nix` - coreTools (allowed commands)
- `gemini-permissions-ask.nix` - Reference only (Gemini has no ask mode)
- `gemini-permissions-deny.nix` - excludeTools (permanently blocked)

**Permission model**:

- **ReadFileTool, GlobTool, GrepTool**: Core read-only tools (always allowed)
- **ShellTool(cmd)**: Shell commands with specific restrictions
  - Example: `ShellTool(git status)` allows only `git status`
  - Example: `ShellTool(rm -rf /)` in excludeTools blocks permanently
- **WebFetchTool**: Web fetching capabilities

**To add commands permanently**:

1. Edit appropriate file in `modules/home-manager/permissions/`
2. Add to `coreTools` (allow) or `excludeTools` (deny)
3. Use format: `ShellTool(command)` for shell commands
4. Commit and rebuild

**Security notes**:

- Gemini CLI has no "ask" mode - commands are either allowed or blocked
- The ask file exists for reference to maintain sync with Claude/Copilot
- See: <https://google-gemini.github.io/gemini-cli/docs/get-started/configuration.html>

## GitHub Copilot CLI Permission Management

**Strategy**: Directory trust model + runtime CLI flags

**Configuration location**: `~/.copilot/config.json`

**Permission files** (`modules/home-manager/permissions/`):

- `copilot-permissions-allow.nix` - trusted_folders (directory trust)
- `copilot-permissions-ask.nix` - Reference only (Copilot uses CLI flags)
- `copilot-permissions-deny.nix` - Recommended --deny-tool flags

**Permission model**:

- **Directory trust**: Copilot requires explicit directory approval (config.json)
- **Tool permissions**: Controlled via CLI flags (NOT config file)
  - `--allow-tool 'shell'`: Allow all shell commands
  - `--allow-tool 'write'`: Allow file writes
  - `--deny-tool 'shell(rm)'`: Block specific shell commands
  - Supports glob patterns: `--deny-tool 'shell(npm run test:*)'`

**Runtime usage**:

```bash
# Allow all tools except dangerous commands
copilot --allow-all-tools --deny-tool 'shell(rm -rf)'

# Allow shell but deny specific commands
copilot --allow-tool 'shell' --deny-tool 'shell(git push)'

# Block MCP server tools
copilot --deny-tool 'My-MCP-Server(tool_name)'
```

**To modify trusted directories**:

1. Edit `modules/home-manager/permissions/copilot-permissions-allow.nix`
2. Add/remove paths in `trustedDevelopmentDirs` or `trustedConfigDirs`
3. Commit and rebuild

**Note**: Unlike Claude/Gemini, Copilot's command-level permissions require
runtime flags. The config file only manages directory trust. The ask file
exists for reference to maintain sync with Claude/Gemini structures.

## VS Code GitHub Copilot Configuration

**Strategy**: Full Nix-managed settings for reproducibility

**Configuration location**: Merged into VS Code `settings.json`

**Nix-managed** (`modules/home-manager/vscode/copilot-settings.nix`):

- Comprehensive GitHub Copilot settings for VS Code editor
- Merged with other VS Code settings in common.nix
- All settings fully declarative and version controlled

**Key settings categories**:

- **Authentication**: GitHub/GitHub Enterprise configuration
- **Code completions**: Inline suggestions, Next Edit Suggestions (NES)
- **Chat & agents**: AI chat, code discovery, custom instructions
- **Security**: Language-specific enable/disable, privacy controls
- **Experimental**: Preview features, model selection

**To modify settings**:

1. Edit `modules/home-manager/vscode/copilot-settings.nix`
2. Update settings following VS Code's `github.copilot.*` namespace
3. Commit and rebuild

**Common customizations**:

- Enable/disable per language: `"github.copilot.enable"`
- Chat features: `"chat.*"` settings
- Inline suggestions: `"editor.inlineSuggest.*"`
- Enterprise auth: `"github.copilot.advanced.authProvider"`

**Reference**: <https://code.visualstudio.com/docs/copilot/reference/copilot-settings>

## AI CLI Tools Comparison

| Feature | Claude Code | Gemini CLI | Copilot CLI | VS Code Copilot |
|---------|-------------|------------|-------------|-----------------|
| **Config file** | `.claude/settings.json` | `.gemini/settings.json` | `.copilot/config.json` | VS Code `settings.json` |
| **Permission model** | allow/ask/deny lists | coreTools/excludeTools | trusted_folders + flags | settings-based |
| **Command format** | `Bash(cmd:*)` | `ShellTool(cmd)` | `shell(cmd)` patterns | N/A (editor-based) |
| **Runtime control** | settings.local.json | settings.json | CLI flags | VS Code UI |
| **Nix file** | `permissions/claude-*.nix` | `permissions/gemini-*.nix` | `permissions/copilot-*.nix` | `vscode/copilot-settings.nix` |
| **Categories** | 24 categories, 277+ cmds | Mirrors Claude structure | Directory trust only | 50+ settings |
| **Security model** | Three-tier (allow/ask/deny) | Two-tier (allow/exclude) | Trust + runtime flags | Per-language enable |

**Consistency philosophy**:

- CLI tools (Claude, Gemini, Copilot) use same categorized command structure
- Same principle of least privilege across all tools
- Nix ensures reproducible, version-controlled configuration
- Different syntax, same security approach

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

## Workflow

1. Make changes to nix files
2. **Commit to git** (flakes requirement)
3. Test build: `nix flake check`
4. Create PR and **wait for user approval**
5. After merge, rebuild (see [RUNBOOK.md](RUNBOOK.md#everyday-commands))
6. Update CHANGELOG.md for significant changes

## Anthropic Ecosystem Integration

**Comprehensive integration** of official Anthropic Claude Code repositories.

**Documentation**: See [docs/ANTHROPIC-ECOSYSTEM.md](docs/ANTHROPIC-ECOSYSTEM.md) for complete reference.

**Quick Overview**:

- **12 official plugins** enabled (git, review, security, UI/UX, output styles, migration)
- **2 plugin marketplaces** configured (claude-code + claude-plugins-official)
- **4 cookbook commands** + **1 agent** installed from claude-cookbooks
- **Skills system** integrated from anthropics/skills
- **Pattern references** for agent workflows documented
- **SDK dev shells** for Python and TypeScript development
- **GitHub Actions** for CI/CD (Claude review, Nix CI, Markdown lint)

**Configuration files**:

- `modules/home-manager/ai-cli/claude-plugins.nix` - Plugin marketplace & enabled plugins
- `modules/home-manager/ai-cli/claude-skills.nix` - Skills configuration
- `modules/home-manager/ai-cli/claude-patterns.nix` - Cookbook pattern references
- `shells/claude-sdk-python/` - Python SDK development shell
- `shells/claude-sdk-typescript/` - TypeScript SDK development shell
- `.github/workflows/claude.yml` - Claude Code review workflow
- `.github/workflows/nix-ci.yml` - Nix flake validation workflow
- `.github/workflows/markdownlint.yml` - Markdown linting workflow

**Flake inputs**:

- `claude-code-plugins` - Main CLI tool with plugins
- `claude-cookbooks` - Patterns, agents, skills, examples
- `claude-plugins-official` - Curated plugin directory
- `anthropic-skills` - Public skills repository

**To use**:

- All slash commands auto-discovered: `/help` to list
- SDK shells: `nix develop ~/.config/nix/shells/claude-sdk-python`
- Update repos: `nix flake update` then rebuild

## Agent OS Integration

**Spec-driven development system** for AI coding agents.

**Documentation**: See [docs/ANTHROPIC-ECOSYSTEM.md](docs/ANTHROPIC-ECOSYSTEM.md) for complete reference (includes Agent OS section).

**Quick Overview**:

- **7 Agent OS commands** (plan-product, write-spec, create-tasks, implement-tasks, etc.)
- **8 specialized agents** (product-planner, spec-writer, implementer, etc.)
- **Standards as skills** (optional) - backend, frontend, global, testing standards
- **Workflows** (optional) - structured multi-step development processes
- **Unified directory structure** - coexists with ai-assistant-instructions and Anthropic content

**Configuration**:

```nix
programs.agent-os = {
  enable = true;                      # Enable Agent OS
  claudeCodeCommands = true;          # Install slash commands
  useClaudeCodeSubagents = true;      # Enable specialized agents
  standardsAsClaudeCodeSkills = true; # Expose standards as skills (optional)
  exposeWorkflows = true;             # Expose workflow templates (optional)
};
```

**Location**: `modules/home-manager/ai-cli/agent-os/default.nix`

**Available Commands**:

- `/plan-product` - Product planning workflow
- `/shape-spec` - Specification shaping
- `/write-spec` - Write technical specification
- `/create-tasks` - Break spec into tasks
- `/implement-tasks` - Execute implementation
- `/orchestrate-tasks` - Multi-task coordination
- `/improve-skills` - Skill improvement loop

**Skills Directory** (when `standardsAsClaudeCodeSkills = true`):

- `~/.claude/skills/backend-*.md` - Backend standards
- `~/.claude/skills/frontend-*.md` - Frontend standards
- `~/.claude/skills/global-*.md` - Global standards
- `~/.claude/skills/testing-*.md` - Testing standards
- `~/.claude/skills/TEMPLATE.md` - Skill template

**Workflows Directory** (when `exposeWorkflows = true`):

- `~/agent-os/workflows/implementation/` - Task execution workflows
- `~/agent-os/workflows/planning/` - Product planning workflows
- `~/agent-os/workflows/specification/` - Spec creation workflows

**To use**:

- Commands: `claude /plan-product`, `claude /create-tasks`
- Skills: Automatically applied by Claude based on context
- Update: `nix flake lock --update-input agent-os` then rebuild

**Reference**: [Agent OS Repository](https://github.com/JacobPEvans/agent-os) | [Agent OS Docs](https://buildermethods.com/agent-os)

## Permission Reference (Load Last for Context Freshness)

Review these permission files to understand what commands are pre-approved:

**User-level** (`~/.claude/settings.json`):

- Generated from `.claude/permissions/allow.json` in the `ai-assistant-instructions` repository
- Contains 280+ pre-approved commands across 25 categories
- Includes: git operations, nix commands, darwin-rebuild, testing tools

**Project-level** (`.claude/settings.local.json`):

- Project-specific overrides (if present)
- Can extend or restrict user-level permissions

**Key pre-approved operations for development workflow:**

- All git commands (status, add, commit, push, branch, checkout, etc.)
- `nix flake check`, `nix flake update`, `nix build`, `nix develop`
- `sudo darwin-rebuild switch --flake .`
- `pre-commit run --all-files`
- `markdownlint-cli2`
- `gh pr create`, `gh pr list`, `gh pr view`

**Denied operations** (see `.claude/permissions/deny.json`):

- Destructive system commands
- Force push to protected branches
- Disabling security features

When uncertain about Claude permissions, check `.claude/permissions/{allow,ask,deny}.json`
in the `ai-assistant-instructions` repository. Gemini and Copilot permissions are in
`modules/home-manager/permissions/`.
