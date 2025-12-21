# Anthropic Claude Code Ecosystem Integration

Comprehensive reference for the integrated Anthropic Claude Code ecosystem in this Nix repository.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Plugins](#plugins)
- [Commands & Agents](#commands--agents)
- [Skills](#skills)
- [Patterns](#patterns)
- [SDK Development](#sdk-development)
- [GitHub Actions](#github-actions)
- [Agent OS Integration](#agent-os-integration)
- [Migration Notes](#migration-notes)
- [Resources](#resources)

---

## Overview

This repository integrates the complete Anthropic Claude Code ecosystem, providing:

- **12 official plugins** from `anthropics/claude-code`
- **2 plugin marketplaces** (claude-code + claude-plugins-official)
- **4 cookbook commands** and **1 agent** from `anthropics/claude-cookbooks`
- **Skills system** from `anthropics/skills`
- **Pattern references** for agent workflows
- **SDK development shells** for Python and TypeScript
- **GitHub Actions templates** for CI/CD integration

### Integration Tiers

| Tier | Priority | Repositories | Status |
|------|----------|--------------|--------|
| **Tier 1: Core** | High | claude-code, claude-cookbooks, claude-plugins-official, skills | Integrated |
| **Tier 2: SDK** | Medium | claude-agent-sdk-python, claude-agent-sdk-typescript | Dev Shells |
| **Tier 3: Learning** | Low | claude-quickstarts, courses | Referenced |

---

## Architecture

### Flake Inputs

All Anthropic repositories are defined as flake inputs in `flake.nix`:

```nix
inputs = {
  # Core integration
  claude-code-plugins = {
    url = "github:anthropics/claude-code";
    flake = false;
  };

  claude-cookbooks = {
    url = "github:anthropics/claude-cookbooks";
    flake = false;
  };

  # Plugin marketplace
  claude-plugins-official = {
    url = "github:anthropics/claude-plugins-official";
    flake = false;
  };

  # Skills system
  anthropic-skills = {
    url = "github:anthropics/skills";
    flake = false;
  };
};
```

### Module Structure

```text
modules/home-manager/ai-cli/
├── claude.nix                    # Main Claude Code settings
├── claude-plugins.nix            # Plugin marketplace & enabled plugins
├── claude-community-commands.nix # Community-contributed commands
├── claude-skills.nix             # Skills configuration
└── claude-patterns.nix           # Cookbook pattern references
```

### Configuration Flow

```text
flake.nix (inputs)
    |
extraSpecialArgs (pass to home-manager)
    |
claude.nix (import child modules)
    |
claude-plugins.nix (configure plugins & marketplaces)
    |
settings.json (merged configuration)
```

---

## Plugins

### Enabled Plugins (12)

All plugins are from the `anthropics/claude-code` marketplace:

#### Git Workflow

- **commit-commands** - `/commit`, `/commit-push-pr`, `/clean_gone`

#### Code Review & Quality

- **code-review** - Multi-agent PR review with confidence scoring
- **pr-review-toolkit** - Specialized review agents

#### Feature Development

- **feature-dev** - 7-phase feature development workflow

#### Security

- **security-guidance** - Security monitoring hook

#### Plugin/Hook Development

- **plugin-dev** - Toolkit for creating Claude Code plugins
- **hookify** - Custom hook creation

#### SDK Development

- **agent-sdk-dev** - Agent SDK development kit

#### UI/UX Design

- **frontend-design** - UI/UX design guidance

#### Output Styles

- **explanatory-output-style** - Educational insights hook
- **learning-output-style** - Interactive learning mode

#### Experimental

- **ralph-wiggum** - Autonomous iteration loops (commented out by default)

### Plugin Marketplaces

Two marketplaces are configured in `claude-plugins.nix`:

1. **anthropics/claude-code** - Official core plugins
2. **anthropics/claude-plugins-official** - Curated plugin directory

Plugins are fetched on-demand when enabled. The marketplace configuration follows the schema:

```nix
marketplaces = {
  "anthropics/claude-code" = {
    source = {
      source = "git";
      url = "https://github.com/anthropics/claude-code.git";
    };
  };
};
```

### Managing Plugins

To enable/disable plugins, edit `modules/home-manager/ai-cli/claude-plugins.nix`:

```nix
enabledPlugins = {
  "plugin-name@anthropics/claude-code" = true;  # Enable
  # "plugin-name@anthropics/claude-code" = true; # Disable (comment out)
};
```

Then rebuild (see [RUNBOOK.md](../RUNBOOK.md#everyday-commands)).

---

## Commands & Agents

### Cookbook Commands (4)

From `anthropics/claude-cookbooks`, installed to `~/.claude/commands/`:

| Command | Description |
|---------|-------------|
| `review-issue` | GitHub issue review |
| `notebook-review` | Jupyter notebook review |
| `model-check` | Model validation |
| `link-review` | Link verification |

### Cookbook Agents (1)

From `anthropics/claude-cookbooks`, installed to `~/.claude/agents/`:

| Agent | Description |
|-------|-------------|
| `code-reviewer` | Senior code review agent |

### Community Commands (4)

From community contributors, installed to `~/.claude/commands/`:

| Command | Description | Source |
|---------|-------------|--------|
| `shape-issues` | Shape raw ideas into actionable GitHub Issues | roksechs |
| `resolve-issues` | Analyze and resolve GitHub Issues efficiently | roksechs |
| `review-pr` | Comprehensive PR review with quality checks | roksechs |
| `resolve-pr-review-thread` | Resolve PR review comments systematically | roksechs |

### Usage

All commands are available as slash commands in Claude Code:

```bash
claude /review-issue    # Review an issue
claude /shape-issues    # Shape issues (community)
```

---

## Skills

### Skills System

Skills from `anthropics/skills` provide reusable capabilities:

- Document generation
- Code analysis
- Data processing
- Workflow automation

### Configuration

Skills are managed in `modules/home-manager/ai-cli/claude-skills.nix`:

```nix
selectedSkills = [
  # "document-generator"
  # "code-analyzer"
  # "workflow-automator"
];
```

**Note**: Skills are commented out by default. Uncomment desired skills and rebuild to enable.

Skills are installed to `~/.claude/skills/` and auto-discovered by Claude Code.

---

## Patterns

### Agent Workflow Patterns

From `anthropics/claude-cookbooks`, documented in `claude-patterns.nix`:

#### Basic Workflows

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **Prompt Chaining** | Sequential prompts where output -> input | Multi-step analysis, document pipelines |
| **Parallelization** | Execute multiple tasks concurrently | Batch processing, concurrent API calls |
| **Routing** | Direct requests to specialized agents | Task classification, tool selection |

#### Advanced Workflows

| Pattern | Description | Use Case |
|---------|-------------|----------|
| **Orchestrator-Workers** | Coordinator manages specialized workers | Complex workflows, task delegation |
| **Evaluator-Optimizer** | Iteratively evaluate and improve | Quality improvement, optimization |

### Pattern Notebooks

Patterns are demonstrated in Jupyter notebooks in the `claude-cookbooks` repository:

- `patterns/agents/basic_workflows.ipynb` - Basic patterns
- `patterns/agents/orchestrator_workers.ipynb` - Advanced patterns

### Pattern Usage

Refer to `modules/home-manager/ai-cli/claude-patterns.nix` for pattern documentation.

---

## SDK Development Shells

### Python SDK Shell

Location: `shells/claude-sdk-python/`

**Features**:

- Python 3.11+ with pip and virtualenv
- Anthropic Python SDK
- Development tools: pytest, black, mypy, ruff
- IPython interactive shell

**Usage**:

```bash
cd /path/to/claude-agent-project
nix develop ~/.config/nix/shells/claude-sdk-python
```

**Quick Start**:

```python
from anthropic import Anthropic

client = Anthropic()
message = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello!"}]
)
print(message.content)
```

See `shells/claude-sdk-python/README.md` for full documentation.

### TypeScript SDK Shell

Location: `shells/claude-sdk-typescript/`

**Features**:

- Node.js 20 LTS with npm, yarn, pnpm
- TypeScript compiler and language server
- Development tools: prettier, eslint
- ts-node for direct execution

**Usage**:

```bash
cd /path/to/claude-agent-project
nix develop ~/.config/nix/shells/claude-sdk-typescript
```

**Quick Start**:

```typescript
import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

const message = await client.messages.create({
  model: 'claude-3-5-sonnet-20241022',
  max_tokens: 1024,
  messages: [{ role: 'user', content: 'Hello!' }],
});
console.log(message.content);
```

See `shells/claude-sdk-typescript/README.md` for full documentation.

### With direnv

Create `.envrc` in your project:

```bash
use flake ~/.config/nix/shells/claude-sdk-python
# or
use flake ~/.config/nix/shells/claude-sdk-typescript
```

Then `direnv allow` to auto-load the environment.

---

## GitHub Actions

### Active Workflows

This repository uses three GitHub Actions workflows:

#### Claude Code Review (`claude.yml`)

Automated PR review using [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action).

**Triggers**: Pull requests (opened, synchronize)

**Features**:

- AI-powered code review using Claude
- Runs the `/review-code` command
- Posts review comments on PRs

**Setup**: Add `CLAUDE_CODE_OAUTH_TOKEN` to repository secrets.

#### Nix CI (`nix-ci.yml`)

Validates Nix flake configuration using Determinate Systems actions.

**Triggers**: Push/PR on `*.nix` or `flake.lock` changes

**Features**:

- Installs Nix via [DeterminateSystems/nix-installer-action](https://github.com/DeterminateSystems/nix-installer-action)
- Free caching via [DeterminateSystems/magic-nix-cache-action](https://github.com/DeterminateSystems/magic-nix-cache-action)
- Checks flake.lock health via [DeterminateSystems/flake-checker-action](https://github.com/DeterminateSystems/flake-checker-action)
- Runs `nix flake check` validation

#### Markdown Lint (`markdownlint.yml`)

Validates markdown file formatting.

**Triggers**: Push/PR on `*.md` or `.markdownlint.*` changes

**Features**:

- Uses [DavidAnson/markdownlint-cli2-action](https://github.com/DavidAnson/markdownlint-cli2-action)
- Enforces consistent markdown style
- Configuration in `.markdownlint.json`

### Customization

Workflows can be customized for your needs:

- Adjust triggers (PR events, schedules)
- Configure severity thresholds
- Modify comment formatting
- Add additional checks

---

## Agent OS Integration

Agent OS is a spec-driven development system providing 7 commands, 8 agents, and 16+ skills for AI-assisted development.

**Full documentation**: [docs/AGENT-OS.md](AGENT-OS.md)

**Quick Start**:

```bash
claude /plan-product      # Product planning
claude /write-spec        # Write technical spec
claude /create-tasks      # Generate task list
claude /implement-tasks   # Execute implementation
```

---

## Migration Notes

This section documents commands that have been migrated from custom implementations to official Anthropic plugins.

### Migrated Commands

| Previous Command | Replacement | Notes |
|------------------|-------------|-------|
| `commit` (custom) | `/commit` from `commit-commands` plugin | Official plugin provides identical git commit functionality |
| `review-pr-ci` (cookbook) | `/code-review` from `code-review` plugin | Official plugin has CI integration and multi-agent review |
| `review-pr` (cookbook) | `/code-review` from `code-review` plugin | Official plugin provides comprehensive PR review |

### Using the New Commands

**For git commits:**

```bash
# Previously: /commit
# Now use:
claude /commit              # Create a commit
claude /commit-push-pr      # Commit, push, and create PR (bonus feature)
```

**For PR reviews:**

```bash
# Previously: /review-pr-ci or /review-pr
# Now use:
claude /code-review         # Multi-agent PR review with confidence scoring
```

### Why Migrate?

1. **Reduced maintenance** - Official plugins are maintained by Anthropic
2. **Feature parity** - Official plugins provide equivalent or better functionality
3. **Consistent updates** - Plugins update automatically via marketplace
4. **Community alignment** - Using standard commands improves collaboration

---

## Resources

### Core Repositories

- [anthropics/claude-code](https://github.com/anthropics/claude-code) - Main CLI tool
- [anthropics/claude-cookbooks](https://github.com/anthropics/claude-cookbooks) - Patterns & examples
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) - Plugin directory
- [anthropics/skills](https://github.com/anthropics/skills) - Public skills

### SDKs

- [anthropics/claude-agent-sdk-python](https://github.com/anthropics/claude-agent-sdk-python) - Python SDK
- [anthropics/claude-agent-sdk-typescript](https://github.com/anthropics/claude-agent-sdk-typescript) - TypeScript SDK
- [anthropics/claude-agent-sdk-demos](https://github.com/anthropics/claude-agent-sdk-demos) - SDK demos

### GitHub Actions Repositories

- [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action) - PR review action
- [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review) - Security review action

### Learning Resources

- [anthropics/claude-quickstarts](https://github.com/anthropics/claude-quickstarts) - Deployable templates
- [anthropics/courses](https://github.com/anthropics/courses) - Educational courses

### Documentation

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Claude API Documentation](https://docs.anthropic.com/en/api)
- [Agent Patterns README](https://github.com/anthropics/claude-cookbooks/blob/main/patterns/agents/README.md)
- [Skills README](https://github.com/anthropics/claude-cookbooks/blob/main/skills/README.md)

---

## Maintenance

### Updating Repositories

Update all Anthropic repositories:

```bash
nix flake update
```

Then rebuild (see [RUNBOOK.md](../RUNBOOK.md#everyday-commands)).

Update specific repository:

```bash
nix flake lock --update-input claude-code-plugins
nix flake lock --update-input claude-cookbooks
nix flake lock --update-input claude-plugins-official
nix flake lock --update-input anthropic-skills
```

### Testing Changes

Verify configuration syntax:

```bash
nix flake check ~/.config/nix
```

Check settings.json output:

```bash
cat ~/.claude/settings.json | jq
```

List enabled plugins:

```bash
cat ~/.claude/settings.json | jq '.enabledPlugins'
```

### Troubleshooting

**Plugin not loading**:

1. Verify plugin name in `claude-plugins.nix`
2. Check marketplace configuration
3. Rebuild and restart Claude Code

**Command not found**:

1. Verify command in `claude-plugins.nix` or `claude-community-commands.nix`
2. Check file copied to `~/.claude/commands/`
3. Restart Claude Code to refresh command list

**Skills not working**:

1. Verify skills enabled in `claude-skills.nix`
2. Check files copied to `~/.claude/skills/`
3. Verify skill file format (should be Markdown)

---

## Contributing

To add new plugins, commands, or skills:

1. **Plugins**: Add to `enabledPlugins` in `claude-plugins.nix`
2. **Commands**: Add to `cookbookCommands` or create new command file
3. **Skills**: Add to `selectedSkills` in `claude-skills.nix`
4. **Rebuild**: See [RUNBOOK.md](../RUNBOOK.md#everyday-commands)
5. **Test**: Run `/help` in Claude Code to verify

See [CONTRIBUTING.md](../CONTRIBUTING.md) for full guidelines.
