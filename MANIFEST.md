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
| htop | Interactive process viewer |
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

Note: OrbStack installed via Homebrew cask (`greedy = true`) in `modules/darwin/homebrew.nix` for TCC permission stability. The `programs.orbstack` module (`modules/darwin/apps/orbstack.nix`) still manages the APFS data volume via launchd.

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

All casks that ship a built-in auto-updater use `greedy = true` so that `brew upgrade` (triggered by `onActivation.upgrade = true` on `darwin-rebuild switch`) always installs the latest version rather than deferring to the app's own updater.

| Package | greedy | Description |
|---------|--------|-------------|
| obsidian | yes | Knowledge base / note-taking |
| shortwave | yes | AI-powered email client |
| wispr-flow | yes | AI-powered voice dictation |
| claude | yes | Anthropic Claude desktop app (not in nixpkgs for Darwin) |
| claude-code | yes | Anthropic Claude Code CLI |
| orbstack | yes | Container/Linux VM runtime — cask for TCC permission stability |
| microsoft-teams | yes | Standalone app for multi-account support |
| microsoft-outlook | yes | Email/calendar |
| microsoft-word | yes | Word processor |
| microsoft-excel | yes | Spreadsheet |
| microsoft-powerpoint | yes | Presentation |
| microsoft-onenote | yes | Notes |
| onedrive | yes | Cloud storage sync |

### Mac App Store

Only for apps with no Homebrew cask (App Store exclusives).

| App | ID |
|-----|-----|
| Toggl Track | 1291898086 |
| Monarch Money Tweaks | 6753774259 |

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
