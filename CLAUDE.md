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

## Critical Requirements

### 1. Flakes-Only Configuration
- **NEVER use nix-channels or non-flake commands**
- All changes must be committed to git before rebuild
- Use: `sudo darwin-rebuild switch --flake ~/.config/nix#default`

### 2. Determinate Nix Compatibility
- **NEVER enable nix-darwin's Nix management**
- `nix.enable = false` must remain in darwin/configuration.nix
- Determinate Nix manages the daemon and nix itself

### 3. Nixpkgs First, Manual Homebrew Updates
- **ALL packages from nixpkgs unless impossible**
- Homebrew is fallback ONLY for packages not in nixpkgs
- Search first: `nix search nixpkgs <package>`
- Document why homebrew was needed if used

**Update Strategy:**
- Homebrew `autoUpdate = false` and `upgrade = false` - no automatic updates
- Nix packages update via `nix flake update` (manual)
- Homebrew packages update manually: `brew upgrade --cask <package>`

**Why no auto-updates?**
- `darwin-rebuild switch` should be fast and predictable
- Downloading Homebrew index (30+ MB) on every rebuild is slow
- User controls when to upgrade (avoids surprise breaking changes)

**Current Homebrew Exceptions:**
- `claude-code` - Rapidly-evolving developer tool
  - Nixpkgs version lags behind releases
  - Can't auto-update from read-only nix store
  - Manual upgrade: `brew upgrade --cask claude-code`

### 4. Code Style for Learning
- **Keep comments** - user is learning Nix
- Show empty sections with examples (even if commented out)
- Visibility > minimalism
- Use `_latest` variants (e.g., `nodejs_latest`)

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
**Fix**: `sudo -u jevans brew uninstall <package>`
**Verify**: Backup important configs first (GPG keys, app settings)

### PATH Priority
**Correct order**: Nix paths before homebrew
1. `/Users/jevans/.nix-profile/bin`
2. `/etc/profiles/per-user/jevans/bin`
3. `/run/current-system/sw/bin` ← nix packages
4. `/nix/var/nix/profiles/default/bin`
5. `/opt/homebrew/bin` ← fallback only

**If wrong**: Check `~/.zprofile` for manual homebrew PATH additions

### VS Code Deprecated API
**Use**: `programs.vscode.profiles.default.userSettings`
**NOT**: `programs.vscode.userSettings`

## Claude Code Permission Management

**Layered Strategy**: Nix manages baseline, settings.local.json for ad-hoc approvals

**Nix-managed** (`~/.claude/settings.json`):
- Defined in `home/claude-permissions.nix`
- 277+ commands in 24 categories
- Version controlled, reproducible
- Updated via darwin-rebuild

**User-managed** (`~/.claude/settings.local.json`):
- NOT managed by Nix (intentionally writable)
- Claude writes here on "accept indefinitely"
- Machine-local only

**To add commands permanently**:
1. Edit `home/claude-permissions.nix`
2. Add to appropriate category
3. Commit and rebuild

**For quick approval**: Just click "accept indefinitely" in Claude UI

## Gemini CLI Permission Management

**Strategy**: Nix-managed configuration using coreTools and excludeTools

**Configuration location**: `~/.gemini/settings.json`

**Nix-managed** (`home/gemini-permissions.nix`):
- `coreTools`: List of allowed built-in tools and shell commands
- `excludeTools`: List of permanently blocked commands
- Mirrors Claude Code's permission structure for consistency
- Uses `ShellTool(command)` syntax for shell command restrictions

**Permission model**:
- **ReadFileTool, GlobTool, GrepTool**: Core read-only tools (always allowed)
- **ShellTool(cmd)**: Shell commands with specific restrictions
  - Example: `ShellTool(git status)` allows only `git status`
  - Example: `ShellTool(rm -rf /)` in excludeTools blocks permanently
- **WebFetchTool**: Web fetching capabilities

**To add commands permanently**:
1. Edit `home/gemini-permissions.nix`
2. Add to appropriate category in `coreTools` or `excludeTools`
3. Use format: `ShellTool(command)` for shell commands
4. Commit and rebuild

**Security notes**:
- Command-specific restrictions use simple string matching
- Not a security boundary - use for workflow control
- Explicitly list allowed commands in coreTools for safety
- See: https://google-gemini.github.io/gemini-cli/docs/get-started/configuration.html

## GitHub Copilot CLI Permission Management

**Strategy**: Directory trust model + runtime CLI flags

**Configuration location**: `~/.copilot/config.json`

**Nix-managed** (`home/copilot-permissions.nix`):
- `trusted_folders`: Array of directory paths where Copilot can operate
- Default trusted directories: `~/projects`, `~/repos`, `~/.config/nix`
- Recommended CLI flag patterns documented in comments

**Permission model**:
- **Directory trust**: Copilot requires explicit directory approval
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
1. Edit `home/copilot-permissions.nix`
2. Add/remove paths in `trustedDevelopmentDirs` or `trustedConfigDirs`
3. Commit and rebuild

**Implementation options**:
- **Shell alias**: Add to ~/.zshrc or Nix shell config
- **Wrapper script**: Create script with preferred flags
- **Per-session**: Manually specify flags when invoking copilot

**Note**: Unlike Claude/Gemini, Copilot's command-level permissions require
runtime flags. The config file only manages directory trust.

## VS Code GitHub Copilot Configuration

**Strategy**: Full Nix-managed settings for reproducibility

**Configuration location**: Merged into VS Code `settings.json`

**Nix-managed** (`home/vscode-copilot-settings.nix`):
- Comprehensive GitHub Copilot settings for VS Code editor
- Merged with other VS Code settings in `home.nix`
- All settings fully declarative and version controlled

**Key settings categories**:
- **Authentication**: GitHub/GitHub Enterprise configuration
- **Code completions**: Inline suggestions, Next Edit Suggestions (NES)
- **Chat & agents**: AI chat, code discovery, custom instructions
- **Security**: Language-specific enable/disable, privacy controls
- **Experimental**: Preview features, model selection

**To modify settings**:
1. Edit `home/vscode-copilot-settings.nix`
2. Update settings following VS Code's `github.copilot.*` namespace
3. Commit and rebuild

**Common customizations**:
- Enable/disable per language: `"github.copilot.enable"`
- Chat features: `"chat.*"` settings
- Inline suggestions: `"editor.inlineSuggest.*"`
- Enterprise auth: `"github.copilot.advanced.authProvider"`

**Reference**: https://code.visualstudio.com/docs/copilot/reference/copilot-settings

## AI CLI Tools Comparison

| Feature | Claude Code | Gemini CLI | Copilot CLI | VS Code Copilot |
|---------|-------------|------------|-------------|-----------------|
| **Config file** | `.claude/settings.json` | `.gemini/settings.json` | `.copilot/config.json` | VS Code `settings.json` |
| **Permission model** | allow/ask/deny lists | coreTools/excludeTools | trusted_folders + flags | settings-based |
| **Command format** | `Bash(cmd:*)` | `ShellTool(cmd)` | `shell(cmd)` patterns | N/A (editor-based) |
| **Runtime control** | settings.local.json | settings.json | CLI flags | VS Code UI |
| **Nix file** | `claude-permissions.nix` | `gemini-permissions.nix` | `copilot-permissions.nix` | `vscode-copilot-settings.nix` |
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
3. Test build: `nix build ~/.config/nix#darwinConfigurations.default.system`
4. Create PR and **wait for user approval**
5. After merge, apply: `sudo darwin-rebuild switch --flake ~/.config/nix#default`
6. Update CHANGELOG.md for significant changes
