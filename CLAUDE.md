# AI Agent Instructions for Nix Configuration

**Strict guidance for AI agents modifying this nix-darwin configuration.**

## Table of Contents

- [Scope of This Document](#scope-of-this-document)
- [Enforced Git Development Workflow](#enforced-git-development-workflow)
- [Command Execution Preferences](#command-execution-preferences)
- [Critical Requirements](#critical-requirements)
- [Task Management Workflow](#task-management-workflow)
- [Common Mistakes to Avoid](#common-mistakes-to-avoid)
- [Claude Code Permission Management](#claude-code-permission-management)
- [Gemini CLI Permission Management](#gemini-cli-permission-management)
- [GitHub Copilot CLI Permission Management](#github-copilot-cli-permission-management)
- [VS Code GitHub Copilot Configuration](#vs-code-github-copilot-configuration)
- [AI CLI Tools Comparison](#ai-cli-tools-comparison)
- [Pull Request Workflow](#pull-request-workflow)
- [Workflow](#workflow)
- [Anthropic Ecosystem Integration](#anthropic-ecosystem-integration)
- [Agent OS Integration](#agent-os-integration)
- [Permission Reference](#permission-reference-load-last-for-context-freshness)

**Navigation Note**: Use this TOC to jump to specific sections. Referenced docs
([TESTING.md](TESTING.md), [RUNBOOK.md](RUNBOOK.md),
[docs/ANTHROPIC-ECOSYSTEM.md](docs/ANTHROPIC-ECOSYSTEM.md)) each have their own TOC.
You do not need to read entire files - navigate via TOC links to relevant sections.

---

## Scope of This Document

This file contains **AI-specific instructions only** - rules and patterns that AI agents need beyond their base training. It should NOT contain:

- General project documentation (belongs in README.md)
- Directory structure or file listings (belongs in README.md)
- Setup guides or troubleshooting (belongs in SETUP.md or TROUBLESHOOTING.md)
- Historical changes (belongs in CHANGELOG.md)
- Future plans (belongs in PLANNING.md)

**Rule**: If information is useful for humans reading project docs, it belongs in README.md or other project files, not here.

## Enforced Git Development Workflow

**MANDATORY for all changes.** Follow without exception.

### Before Making Changes

1. Check current branch - determine if change relates to current worktree+branch
2. If on `main`: create new feature branch before modifying any files
3. If on unrelated branch: switch to main, pull latest, create new dedicated branch
4. Never make changes directly on `main`

### After Completing Changes

1. Stage all changes
2. Run full test cycle per [TESTING.md](TESTING.md#basic-local-change-testing)
3. **NEVER disable or bypass git pre-commit hooks** - always fix the root cause
4. Commit with descriptive message
5. Push to remote

### Pull Request Requirement

- Always create a PR after testing if one doesn't exist for current branch
- Do not ask user to run tests - run them yourself using pre-approved commands
- Complete the full cycle: branch → change → test → commit → push → PR

### Background Monitoring (On Every PR Create and Push)

After creating a PR or pushing to a branch with an open PR, spawn TWO background tasks:

1. **CI Check Monitor** - Watch GitHub Action checks (`gh pr checks` or `gh run watch`).
   When checks fail, analyze the failure and attempt to fix the root cause.
   After fixing, commit and push to trigger new CI run.
   Repeat until checks pass or issue requires user input.

2. **PR Review Monitor** - Watch for completed PR reviews (`gh pr view` or `gh api`).
   When a reviewer completes their review (comments, changes requested, or approved),
   automatically invoke `/rok-respond-to-reviews` to address feedback.
   Continue monitoring until PR is merged or closed.

Both tasks run concurrently in background while you continue other work.

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
3. `/run/current-system/sw/bin` ← nix packages
4. `/nix/var/nix/profiles/default/bin`
5. `/opt/homebrew/bin` ← fallback only

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
# Count permissions in source (should match after rebuild)
jq '.permissions | length' ~/git/ai-assistant-instructions/.claude/permissions/allow.json

# Count permissions in deployed settings
jq '.permissions.allow | length' ~/.claude/settings.json

# Check for project-level overrides in current directory
cat ./.claude/settings.local.json 2>/dev/null | jq '.allow | length'
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
- **6 cookbook commands** + **1 agent** installed from claude-cookbooks
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

- Generated from `modules/home-manager/permissions/claude-permissions-allow.nix`
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

**Denied operations** (see `claude-permissions-deny.nix`):

- Destructive system commands
- Force push to protected branches
- Disabling security features

When uncertain about permissions, check the source files in `modules/home-manager/permissions/`.
