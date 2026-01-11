# AI CLI Tools Permission Management

Comprehensive guide to managing permissions for Claude Code, Gemini CLI, and GitHub Copilot in this Nix-managed environment.

## Overview

All AI CLI tools use a Nix-managed permission system with the following philosophy:

- **Declarative**: Permissions defined in Nix or JSON files
- **Reproducible**: Same permissions across all machines
- **Layered**: Global baseline with local overrides
- **Principle of least privilege**: Deny by default, allow explicitly

## Quick Reference

| Feature | Claude Code | Gemini CLI | Copilot CLI | VS Code Copilot |
|---------|-------------|------------|-------------|-----------------|
| **Config file** | `.claude/settings.json` | `.gemini/settings.json` | `.copilot/config.json` | VS Code `settings.json` |
| **Permission model** | allow/ask/deny lists | tools.allowed/tools.exclude | trusted_folders + flags | settings-based |
| **Command format** | `Bash(cmd:*)` | `ShellTool(cmd)` | `shell(cmd)` patterns | N/A (editor-based) |
| **Runtime control** | settings.local.json | settings.json | CLI flags | VS Code UI |
| **Nix source** | `ai-assistant-instructions` | `permissions/gemini-*.nix` | `permissions/copilot-*.nix` | `vscode/copilot-settings.nix` |
| **Categories** | 323+ command patterns | Mirrors Claude structure | Directory trust only | 50+ settings |
| **Security model** | Three-tier (allow/ask/deny) | Two-tier (allow/exclude) | Trust + runtime flags | Per-language enable |

## Claude Code

**Layered Strategy**: Nix manages baseline, settings.local.json for ad-hoc approvals

### Permission Sources

**Nix-managed** (`ai-assistant-instructions` flake input):

- `allow/` directory - Auto-approved commands (300+ patterns)
- `ask/` directory - Commands requiring user confirmation (100+ patterns)
- `deny/` directory - Permanently blocked (catastrophic operations)
- Located in `agentsmd/permissions/` within the flake input
- Compiled into `~/.claude/settings.json` (read-only, Nix-managed)

**User-managed** (`~/.claude/settings.local.json`):

- NOT managed by Nix (intentionally writable)
- Claude writes here on "accept indefinitely"
- Machine-local only

### Three-Tier Permission Hierarchy

Claude Code evaluates permissions in this order (most restrictive first):

1. **Deny** (highest priority) - Permanently blocked commands
   - Example: `git commit --no-verify`, `rm -rf /`, package installs
   - Never executes, no prompt shown

2. **Ask** (middle tier) - Require user confirmation
   - Example: `git merge`, `git reset`, `docker exec`, `kubectl delete`
   - User prompted each time (or can "accept indefinitely" for local override)

3. **Allow** (lowest priority) - Auto-approved commands
   - Example: `git status`, `docker ps`, `kubectl get`
   - Executes silently without prompts

### Permission Format and Transformation

**CRITICAL**: Source permission files use tool-agnostic format without wildcards.
The Nix formatter automatically adds wildcards when generating tool-specific output.

**Source format** (in `ai-assistant-instructions`):

```json
{
  "commands": [
    "git",
    "docker",
    "git merge",
    "npm run"
  ]
}
```

**Generated format** (in `~/.claude/settings.json`):

```json
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(docker:*)"
    ],
    "ask": [
      "Bash(git merge:*)"
    ]
  }
}
```

**Transformation examples**:

- Source: `"git"` → Output: `"Bash(git:*)"`
- Source: `"git merge"` → Output: `"Bash(git merge:*)"`

**WRONG** (do NOT use `:*` in source files):

- Source: `"git:*"` → Output: `"Bash(git:*:*)"` ✗ (invalid double wildcard)

Pre-commit and CI validation hooks reject source patterns ending with `:*` to
prevent double-wildcard issues, and also verify that the generated output
contains no `:*:*` patterns.

### Directory Access

Configured via `additionalDirectories` in `modules/home-manager/ai-cli/claude.nix`:

- Grants Claude read access to directories outside working directory
- Prevents "allow reading from X/" prompts
- Default: `~/`, `~/.claude/`, `~/.config/`

### Adding Commands Permanently

1. Edit appropriate JSON file in `ai-assistant-instructions` repository
2. Add to appropriate category (allow, ask, or deny)
3. Update flake input: `nix flake lock --update-input ai-assistant-instructions`
4. Rebuild to apply changes

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
   - Rule: Built-in tools use bare names for unconditional approval (e.g., `Read`, `Glob`, `Grep`)
   - Rule: Only 0 or 1 wildcards per pattern, none in the middle
   - Valid: `Bash(git log:*)`, `Read`, `Glob`, `WebFetch(domain:github.com)`
   - Invalid: `Bash(git * status:*)`, `Bash(npm run:*:*)`, `Read(**)`, `Glob(**)`

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

### Key Pre-approved Operations

- All git commands (status, add, commit, push, branch, checkout, etc.)
- `nix flake check`, `nix flake update`, `nix build`, `nix develop`
- `sudo darwin-rebuild switch --flake .`
- `pre-commit run --all-files`
- `markdownlint-cli2`
- `gh pr create`, `gh pr list`, `gh pr view`

### Denied Operations

See `.claude/permissions/deny.json`:

- Destructive system commands
- Force push to protected branches
- Disabling security features

## Gemini CLI

**Strategy**: Nix-managed configuration using tools.allowed and tools.exclude

### CRITICAL: tools.allowed vs tools.core

Per the official Gemini CLI schema:

- `tools.allowed` = "Tool names that bypass the confirmation dialog" (**AUTO-APPROVE**)
- `tools.core` = "Allowlist to RESTRICT built-in tools to a specific set" (**LIMITS** usage!)

**NEVER use tools.core for auto-approval!** Using `tools.core` restricts what tools Gemini can use.
Always use `tools.allowed` for commands you want to auto-approve.

Schema reference: <https://github.com/google-gemini/gemini-cli/blob/main/schemas/settings.schema.json>

### Configuration

**Location**: `~/.gemini/settings.json`

**Permission files** (`modules/home-manager/permissions/`):

- `gemini-permissions-allow.nix` - allowedTools (auto-approved commands → tools.allowed)
- `gemini-permissions-ask.nix` - Reference only (Gemini has no ask mode)
- `gemini-permissions-deny.nix` - excludeTools (permanently blocked → tools.exclude)

### Permission Model

- **ReadFileTool, GlobTool, GrepTool**: Core read-only tools (always allowed)
- **ShellTool(cmd)**: Shell commands with specific restrictions
  - Example: `ShellTool(git status)` allows only `git status`
  - Example: `ShellTool(rm -rf /)` in excludeTools blocks permanently
- **WebFetchTool**: Web fetching capabilities

### Adding Commands

1. Edit appropriate file in `modules/home-manager/permissions/`
2. Add to `allowedTools` (auto-approve) or `excludeTools` (block)
3. Use format: `ShellTool(command)` for shell commands
4. Commit and rebuild

**IMPORTANT**: The Nix attribute `allowedTools` maps to `tools.allowed` in settings.json.
Never rename it to `coreTools` - that would break auto-approval!

### Security Notes

- Gemini CLI has no "ask" mode - commands are either allowed or blocked
- The ask file exists for reference to maintain sync with Claude/Copilot
- See: <https://google-gemini.github.io/gemini-cli/docs/get-started/configuration.html>

## GitHub Copilot CLI

**Strategy**: Directory trust model + runtime CLI flags

### Copilot CLI Configuration

**Location**: `~/.copilot/config.json`

**Permission files** (`modules/home-manager/permissions/`):

- `copilot-permissions-allow.nix` - trusted_folders (directory trust)
- `copilot-permissions-ask.nix` - Reference only (Copilot uses CLI flags)
- `copilot-permissions-deny.nix` - Recommended --deny-tool flags

### Copilot CLI Permission Model

- **Directory trust**: Copilot requires explicit directory approval (config.json)
- **Tool permissions**: Controlled via CLI flags (NOT config file)
  - `--allow-tool 'shell'`: Allow all shell commands
  - `--allow-tool 'write'`: Allow file writes
  - `--deny-tool 'shell(rm)'`: Block specific shell commands
  - Supports glob patterns: `--deny-tool 'shell(npm run test:*)'`

### Runtime Usage

```bash
# Allow all tools except dangerous commands
copilot --allow-all-tools --deny-tool 'shell(rm -rf)'

# Allow shell but deny specific commands
copilot --allow-tool 'shell' --deny-tool 'shell(git push)'

# Block MCP server tools
copilot --deny-tool 'My-MCP-Server(tool_name)'
```

### Modifying Trusted Directories

1. Edit `modules/home-manager/permissions/copilot-permissions-allow.nix`
2. Add/remove paths in `trustedDevelopmentDirs` or `trustedConfigDirs`
3. Commit and rebuild

**Note**: Unlike Claude/Gemini, Copilot's command-level permissions require
runtime flags. The config file only manages directory trust.

## VS Code GitHub Copilot

**Strategy**: Full Nix-managed settings for reproducibility

### VS Code Copilot Configuration

**Location**: Merged into VS Code `settings.json`

**Nix-managed** (`modules/home-manager/vscode/copilot-settings.nix`):

- Comprehensive GitHub Copilot settings for VS Code editor
- Merged with other VS Code settings in common.nix
- All settings fully declarative and version controlled

### Key Settings Categories

- **Authentication**: GitHub/GitHub Enterprise configuration
- **Code completions**: Inline suggestions, Next Edit Suggestions (NES)
- **Chat & agents**: AI chat, code discovery, custom instructions
- **Security**: Language-specific enable/disable, privacy controls
- **Experimental**: Preview features, model selection

### Modifying Settings

1. Edit `modules/home-manager/vscode/copilot-settings.nix`
2. Update settings following VS Code's `github.copilot.*` namespace
3. Commit and rebuild

### Common Customizations

- Enable/disable per language: `"github.copilot.enable"`
- Chat features: `"chat.*"` settings
- Inline suggestions: `"editor.inlineSuggest.*"`
- Enterprise auth: `"github.copilot.advanced.authProvider"`

**Reference**: <https://code.visualstudio.com/docs/copilot/reference/copilot-settings>

## Consistency Philosophy

- CLI tools (Claude, Gemini, Copilot) use same categorized command structure
- Same principle of least privilege across all tools
- Nix ensures reproducible, version-controlled configuration
- Different syntax, same security approach

## Finding Permission Files

| Tool | Permission Location |
|------|---------------------|
| Claude | `ai-assistant-instructions` repo → `.claude/permissions/{allow,ask,deny}.json` |
| Gemini | This repo → `modules/home-manager/permissions/gemini-permissions-*.nix` |
| Copilot CLI | This repo → `modules/home-manager/permissions/copilot-permissions-*.nix` |
| VS Code Copilot | This repo → `modules/home-manager/vscode/copilot-settings.nix` |
