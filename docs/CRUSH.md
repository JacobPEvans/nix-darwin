# Crush AI Coding Agent

Crush is an open-source terminal-based AI coding agent by Charmbracelet.

## Overview

Crush provides an intelligent development companion with:

- **Multi-model support**: Switch between LLMs mid-session while preserving context
- **MCP integration**: Model Context Protocol for external tools
- **LSP support**: Language Server Protocol for code intelligence
- **Agent Skills**: Extensible via Agent Skills standard
- **Cross-platform**: macOS, Linux, Windows, FreeBSD, NetBSD, OpenBSD

**Project**: [github.com/charmbracelet/crush](https://github.com/charmbracelet/crush)

## Installation

**NOTE**: Crush is currently disabled in this configuration due to python3.13-twisted test failures.

Alternative installation methods:

```bash
# Via Nix
nix run github:numtide/nix-ai-tools#crush

# Via Homebrew
brew install charmbracelet/tap/crush

# Via npm
npm install -g @anthropic-ai/crush
```

## Configuration

Configuration file: `~/.config/crush/crush.json`

Managed by: `modules/home-manager/ai-cli/crush.nix`

### Configuration Priority

1. `.crush.json` (project-specific)
2. `crush.json` (project root)
3. `$HOME/.config/crush/crush.json` (global)

### Current Settings

```json
{
  "theme": "auto",
  "providers": {
    "anthropic": { "default_model": "claude-sonnet-4-20250514" },
    "openai": { "default_model": "gpt-4.1" },
    "google": { "default_model": "gemini-2.5-flash" },
    "ollama": { "default_model": "llama3.3", "base_url": "http://localhost:11434" }
  },
  "attribution": {
    "enabled": true,
    "trailer": "AI-assisted-by",
    "value": "Crush (charmbracelet.sh)"
  }
}
```

### Environment Variables

```bash
# Provider API keys
ANTHROPIC_API_KEY="..."
OPENAI_API_KEY="..."
GOOGLE_API_KEY="..." # or GEMINI_API_KEY
GROQ_API_KEY="..."

# Optional configuration
CRUSH_CONFIG="~/.config/crush/crush.json"
CRUSH_DATA="~/.local/share/crush"
```

## Usage

### Interactive Mode (TUI)

```bash
# Start Crush in current directory
crush

# Start with specific model
crush --model claude-sonnet-4

# YOLO mode (bypass all permission prompts - use with caution!)
crush --yolo
```

### Key Features

**Model switching mid-session**: Change models while preserving conversation context.

**Permission gating**: Tool execution requires approval unless in YOLO mode or
command is in allowlist.

**Session persistence**: Conversations saved per-project for context continuity.

## Crush vs Auto-Claude Comparison

### Feature Comparison

| Feature | Crush | Auto-Claude |
|---------|-------|-------------|
| **Provider** | Multi-provider | Anthropic only |
| **Scheduling** | None (wrapper needed) | launchd native |
| **Slack Integration** | Via MCP server | Native Block Kit |
| **Cost Tracking** | None | Per-run budgets |
| **JSONL Logging** | None | Native events.jsonl |
| **Anomaly Detection** | None | Built-in monitor |
| **Control Script** | None | pause/resume/status |
| **MCP Support** | Native | Via Claude Code |
| **LSP Support** | Native | Via Claude Code |
| **License** | MIT | Proprietary |

### Recommendation

**Run both tools in parallel:**

1. **Auto-Claude**: Scheduled maintenance tasks
   - Existing Slack/monitoring infrastructure
   - Budget-controlled runs
   - Automated PR creation

2. **Crush**: Interactive development
   - Multi-provider flexibility
   - Model switching mid-session
   - MCP-based extensibility

## MCP Server Configuration

Configure MCP servers in `crush.json`:

```json
{
  "mcps": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "~"]
    },
    "bitwarden": {
      "command": "~/.npm-packages/bin/mcp-server-bitwarden",
      "args": []
    }
  }
}
```

Environment variable expansion is supported in MCP configs:

```json
{
  "mcps": {
    "example": {
      "command": "example-server",
      "env": {
        "API_KEY": "$MY_API_KEY"
      }
    }
  }
}
```

## LSP Configuration

Configure language servers for code intelligence:

```json
{
  "lsps": {
    "go": {
      "command": "gopls",
      "args": []
    },
    "nix": {
      "command": "nil",
      "args": []
    },
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"]
    }
  }
}
```

## Permissions

Configure permission allowlists:

```json
{
  "permissions": {
    "shell_allowlist": [
      "git status",
      "git diff",
      "ls",
      "cat"
    ]
  }
}
```

Or use YOLO mode for unrestricted access:

```bash
crush --yolo
```

## Commit Attribution

Crush can add trailers to commit messages:

```json
{
  "attribution": {
    "enabled": true,
    "trailer": "AI-assisted-by",
    "value": "Crush (charmbracelet.sh)"
  }
}
```

Result:

```text
feat: add new feature

AI-assisted-by: Crush (charmbracelet.sh)
```

## OrbStack Integration

Crush works with OrbStack/Kubernetes via:

1. **Direct CLI**: Execute `kubectl` commands through Crush's shell
2. **MCP Server**: Configure K8s MCP server for structured operations

```bash
# Example: Use Crush for K8s operations
crush
> Deploy the new version to staging
```

## Related Documentation

- [LLM Agents](LLM-AGENTS.md) - numtide/llm-agents.nix overview
- [Auto-Claude](../modules/home-manager/ai-cli/claude/TESTING.md)
- [Monitoring](MONITORING.md)
- [Anthropic Ecosystem](ANTHROPIC-ECOSYSTEM.md)

## References

- [Crush GitHub](https://github.com/charmbracelet/crush)
- [Charmbracelet](https://charm.sh)
- [Model Context Protocol](https://modelcontextprotocol.org/)
- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix)
