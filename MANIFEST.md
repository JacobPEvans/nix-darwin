# Manifest

Complete inventory of everything installed and managed by this nix-darwin configuration.
Each entry lists the source file where it is declared.

---

## System Packages (nixpkgs)

### Core CLI Tools

Source: `modules/darwin/common.nix`

| Package | Description |
|---------|-------------|
| git | Version control |
| gnupg | GPG encryption and signing |
| vim | Text editor |

### Modern CLI Tools

Source: `modules/darwin/common.nix`

| Package | Description |
|---------|-------------|
| bat | Better cat with syntax highlighting |
| delta | Better git diff viewer with syntax highlighting |
| eza | Modern ls replacement with git integration |
| fd | Faster, user-friendly find alternative |
| fzf | Fuzzy finder for interactive selection |
| gnugrep | GNU grep with zgrep for compressed files |
| gnutar | GNU tar as gtar (Mac-safe tar without .\_ files) |
| btop | Modern process monitor with graphs (daily use) |
| htop | Interactive process viewer |
| mactop | Real-time Apple Silicon CPU/GPU/ANE/thermal monitoring |
| jq | JSON parsing |
| ncdu | NCurses disk usage analyzer |
| ngrep | Network packet grep |
| procps | Process utilities (pgrep, pkill) |
| ripgrep | Fast grep alternative (rg) |
| tldr | Simplified, community-driven man pages |
| tree | Directory tree visualization |
| watchexec | File watcher that re-executes commands on changes |
| yq | YAML/XML/TOML parsing (like jq) |

### Development Tools

Source: `modules/darwin/common.nix`

| Package | Description |
|---------|-------------|
| mas | Mac App Store CLI |
| nodejs | Node.js LTS |
| ollama | LLM runtime (models on /Volumes/Ollama/models) |

---

## Cross-Platform Packages

Source: `modules/common/packages.nix`

### Runtimes

| Package | Description |
|---------|-------------|
| nodejs | Provides npm and npx |
| bun | Fast all-in-one JavaScript runtime (provides bunx) |

### Git Workflow

| Package | Description |
|---------|-------------|
| git-flow-next | Modern git-flow workflow tool (custom buildGoModule, gittower/git-flow-next v1.0.0) |

### Pre-commit and Linters

| Package | Description |
|---------|-------------|
| pre-commit | Git pre-commit hook framework |
| shellcheck | Shell script static analysis |
| shfmt | Shell script formatter |
| bats | Bash Automated Testing System |
| lychee | Link checker for markdown and HTML |
| markdownlint-cli2 | Markdown linter |
| actionlint | GitHub Actions workflow linter |

### Nix Tooling

| Package | Description |
|---------|-------------|
| nixfmt-rfc-style | Official Nix formatter (RFC 166) |
| statix | Nix linter - catches anti-patterns |
| deadnix | Find unused code in .nix files |
| treefmt | Multi-language formatter runner |
| nix-tree | Browse Nix store dependencies interactively |
| check-jsonschema | JSON Schema validator CLI |

### Security and Credentials

| Package | Description |
|---------|-------------|
| bitwarden-cli | CLI for Bitwarden password manager (bw) |
| bws | Bitwarden Secrets Manager CLI |
| doppler | Doppler secrets manager CLI |

### Cloud Infrastructure

| Package | Description |
|---------|-------------|
| awscli2 | AWS CLI v2 |
| aws-vault | Secure AWS credential storage (uses OS keychain) |

### Remote Shell

| Package | Description |
|---------|-------------|
| mosh | Resilient mobile shell using UDP |

### Python

| Package | Description |
|---------|-------------|
| pyright | Static type checker for Python |
| python314 | Python 3.14 (bleeding edge) |
| python312 | Python 3.12 (general development) |
| python310 | Python 3.10 (compatibility testing) |
| uv | Fast Python package manager (also runs EOL versions) |
| python3.withPackages | Unified env: cryptography, grip, ollama, pipx, pygithub |

---

## GUI Applications - System Level

Source: `modules/darwin/common.nix`

| Package | Description |
|---------|-------------|
| bitwarden-desktop | Password manager desktop app |
| raycast | Productivity launcher (replaces Spotlight) |
| swiftbar | Menu bar customization (auto-claude status) |

Note: OrbStack managed via `programs.orbstack` module (`modules/darwin/apps/orbstack.nix`).

---

## GUI Applications - User Level

Source: `hosts/macbook-m4/home.nix`

| Package | Description |
|---------|-------------|
| ghostty-bin | Terminal emulator (unstable overlay) |
| postman | API development environment |
| rapidapi | Full-featured HTTP client |
| antigravity | Google AI-powered IDE (unstable overlay) |
| code-cursor | Cursor AI IDE (VS Code fork) |
| chatgpt | OpenAI ChatGPT desktop app |
| claudebar | Menu bar AI coding assistant quota monitoring |
| ffmpeg | Audio/video recording, conversion, streaming |

---

## AI CLI Tools

Source: `modules/home-manager/ai-cli/ai-tools.nix`

| Package | Method | Description |
|---------|--------|-------------|
| cclint | bunx wrapper | CLAUDE.md linter |
| github-mcp-server | nixpkgs (unstable) | GitHub API MCP server |
| terraform-mcp-server | nixpkgs (unstable) | Terraform/OpenTofu MCP server |
| gemini-cli | nixpkgs (unstable) | Google Gemini CLI |
| codex | nixpkgs (unstable) | OpenAI Codex CLI |
| gh-copilot | bunx wrapper | GitHub Copilot CLI |
| chatgpt (CLI) | bunx wrapper | OpenAI ChatGPT CLI |
| claude-flow | bunx wrapper | AI agent orchestration |
| aider | pipx | AI pair programming |

---

## Homebrew

Source: `modules/darwin/homebrew.nix`

### Brews

| Package | Description |
|---------|-------------|
| ccusage | Claude Code usage analyzer |
| block-goose-cli | Block's Goose AI agent |

### Casks

| Package | Description |
|---------|-------------|
| obsidian | Knowledge base / note-taking |
| shortwave | AI-powered email client |
| claude | Anthropic Claude desktop app |
| claude-code | Anthropic Claude Code CLI |
| wispr-flow | AI-powered voice dictation |

### Mac App Store

| App | ID |
|-----|-----|
| Toggl Track | 1291898086 |
| Monarch Money Tweaks | 6753774259 |
| Microsoft Word | 462054704 |
| Microsoft Excel | 462058435 |
| Microsoft PowerPoint | 462062816 |
| Microsoft Outlook | 985367838 |
| Microsoft OneNote | 784801555 |
| OneDrive | 823766827 |

---

## Programs and Services

Source: `modules/home-manager/common.nix`

| Program | Description |
|---------|-------------|
| zsh | Shell with Oh My Zsh, autosuggestions, syntax highlighting |
| git | Version control with GPG signing, aliases, hooks |
| gh | GitHub CLI with extensions (gh-aw) |
| direnv | Per-project environment loading with nix-direnv |
| vscode | Visual Studio Code with writable settings merge |
| home-manager | User environment management |
| claude | Claude Code ecosystem (plugins, commands, agents, skills, hooks, MCP) |
| claudeStatusline | Powerline-style statusline for Claude Code terminal |

---

## macOS System Settings

| Category | Source | Key Settings |
|----------|--------|--------------|
| Dock | `modules/darwin/dock/` | App layout, behavior, appearance, hot corners |
| Finder | `modules/darwin/finder.nix` | Preferences |
| Keyboard | `modules/darwin/keyboard.nix` | Key repeat, input settings |
| Trackpad | `modules/darwin/trackpad.nix` | Gestures |
| System UI | `modules/darwin/system-ui.nix` | Menu bar, control center, login window |
| Security | `modules/darwin/security.nix` | System security policies |
| Energy | `modules/darwin/energy.nix` | Power management |
| Boot | `modules/darwin/boot-activation.nix` | Creates /run/current-system at boot |
| Logging | `modules/darwin/logging.nix` | Syslog forwarding to remote server |
| File Extensions | `modules/darwin/file-extensions.nix` | File type associations |
| Auto Recovery | `modules/darwin/auto-recovery.nix` | Activation error recovery |

---

## Unstable Overlay

Packages sourced from nixpkgs-unstable for version currency.

Source: `modules/darwin/common.nix` (overlay block)

| Package | Reason |
|---------|--------|
| antigravity | GUI app - fast upstream releases |
| ghostty-bin | GUI app - fast upstream releases |
| ollama | LLM runtime - fast upstream releases |
| codex | AI CLI - stable lags behind upstream |
| gemini-cli | AI CLI - stable lags behind upstream |
| github-mcp-server | AI CLI - stable lags behind upstream |
| terraform-mcp-server | AI CLI - stable lags behind upstream |

---

## Development Shells

Source: `shells/` (see [shells/README.md](shells/README.md) for details)

| Shell | Description |
|-------|-------------|
| ansible | Ansible automation |
| claude-sdk-python | Claude Agent SDK (Python) |
| claude-sdk-typescript | Claude SDK (TypeScript) |
| containers | Container ecosystem (Docker, BuildKit, registry tools) |
| go | Go development (gopls, delve) |
| image-building | Packer with Ansible for multi-platform image builds |
| infrastructure-automation | Complete IaC toolkit (Ansible + Terraform + AWS + Packer) |
| js | Node.js (npm, yarn, pnpm) |
| kubernetes | Kubernetes validation, linting, orchestration, and local testing |
| powershell | PowerShell 7.x scripting |
| python | Basic Python development |
| python-data | Data science / ML (pandas, numpy, jupyter) |
| python310 | Python 3.10 (older compatibility testing) |
| python312 | Python 3.12 (full dev environment) |
| python314 | Python 3.14 (bleeding edge) |
| splunk-dev | Splunk development (Python 3.9 via uv) |
| terraform | Infrastructure as Code (Terraform, Terragrunt, OpenTofu) |

---

## Process Cleanup Mechanisms

Event-based cleanup to prevent orphaned MCP server and subagent processes from
accumulating across Claude Code sessions (workaround for upstream bug #1935).

### Layer 1: zsh zshexit() Hook (Primary)

Source: `modules/home-manager/zsh/process-cleanup.zsh`
Wired via: `modules/home-manager/common.nix` initContent

| Property | Detail |
|----------|--------|
| Trigger | Shell exit — including SIGHUP from Ghostty tab close |
| Scope | Descendants of the current shell PID only (safe: no cross-tab impact) |
| Condition | Inner shell only (SCRIPT_SESSION set by session-logging.zsh) |
| Method | BFS process tree walk via pgrep -P; SIGTERM then SIGKILL after 1s |

### Layer 2: Claude Code stop Hook (Defense-in-Depth)

Source: `process-cleanup@jacobpevans-cc-plugins`
Wired via: `jacobpevans-cc-plugins` flake input → auto-discovered by `development.nix`

| Property | Detail |
|----------|--------|
| Trigger | Claude session exit via /exit or Ctrl+C |
| Scope | System-wide orphans with ppid=1 (reparented to launchd) |
| Targets | terraform-mcp-server, context7-mcp, orphaned node MCP processes |
| Logs | ~/Library/Logs/claude-process-cleanup/cleanup-YYYY-MM-DD.log |
