---
paths: []
---

# Claude Code AI CLI Module Conventions

> **Note**: The AI CLI module (`modules/home-manager/ai-cli/`) has moved to
> [nix-ai](https://github.com/JacobPEvans/nix-ai). This rule is retained for
> reference but no longer triggers on local path changes.

## Settings Configuration

- **Always prefer `settings.json` keys** over environment variables for Claude Code configuration
- Before adding an env var, check if a native JSON key exists at <https://code.claude.com/docs/en/settings>
- If a native key is added upstream for an existing env var, migrate to the native key
- Environment variables are appropriate only when no native JSON key exists (e.g., MCP timeouts, experimental flags)
