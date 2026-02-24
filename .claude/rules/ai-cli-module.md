---
paths:
  - "modules/home-manager/ai-cli/**/*"
---

# Claude Code AI CLI Module Conventions

## Settings Configuration

- **Always prefer `settings.json` keys** over environment variables for Claude Code configuration
- Before adding an env var, check if a native JSON key exists at <https://code.claude.com/docs/en/settings>
- If a native key is added upstream for an existing env var, migrate to the native key
- Environment variables are appropriate only when no native JSON key exists (e.g., MCP timeouts, experimental flags)

## Module Structure

- `claude/options.nix` — All option declarations
- `claude/settings.nix` — Generates `~/.claude/settings.json` from options
- `claude/statusline/` — Statusline configuration (powerline theme)
- `claude/plugins.nix` — Plugin symlink management
- `claude/registry.nix` — Marketplace registry management
- `claude-config.nix` — Configuration values (where options are SET)

## Key Patterns

- New Claude Code settings: add option in `options.nix`, wire in `settings.nix`, set value in `claude-config.nix`
- Single source of truth: `lib/claude-registry.nix` for marketplace format
- Statusline uses `bunx` with semver pinning (`@^1`) — no build-time hash maintenance
- Never manually edit `~/.claude/settings.json` — it's a Nix store symlink
