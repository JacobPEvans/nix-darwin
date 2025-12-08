# Nix Configuration

> Because "it works on my machine" should mean it works on *every* machine.
> Deterministic builds, reproducible environments, and the smug satisfaction of knowing exactly what's installed.

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

[![Nix CI](https://github.com/JacobPEvans/nix/actions/workflows/nix.yml/badge.svg)](https://github.com/JacobPEvans/nix/actions/workflows/nix.yml) [![Markdown Lint](https://github.com/JacobPEvans/nix/actions/workflows/markdownlint.yml/badge.svg)](https://github.com/JacobPEvans/nix/actions/workflows/markdownlint.yml) [![File Size](https://github.com/JacobPEvans/nix/actions/workflows/file-length.yml/badge.svg)](https://github.com/JacobPEvans/nix/actions/workflows/file-length.yml)

## What Is This?

A flakes-only nix-darwin configuration for M4 Max MacBook Pro. Manages system packages, macOS settings, dotfiles, and AI CLI tools - all declaratively.

Think of it as infrastructure-as-code, but for your laptop.

## Quick Start

```bash
# Rebuild after config changes
sudo darwin-rebuild switch --flake ~/.config/nix

# Search for a package
nix search nixpkgs <name>

# Rollback if something breaks
sudo darwin-rebuild --rollback
```

See [RUNBOOK.md](RUNBOOK.md) for detailed procedures.

## Directory Structure

```text
.
├── flake.nix                  # Main entry point
├── hosts/                     # Host-specific configurations
│   └── macbook-m4/            # Active M4 Max MacBook Pro
├── modules/                   # Reusable configuration modules
│   ├── common/                # Cross-platform packages
│   ├── darwin/                # macOS system settings
│   └── home-manager/          # User environment (shell, git, AI CLIs)
├── shells/                    # Development environment templates
└── lib/                       # Shared configuration variables
```

Full details in [ARCHITECTURE.md](ARCHITECTURE.md).

## Key Components

| Component | What It Does |
|-----------|--------------|
| **Determinate Nix** | Manages Nix itself - daemon, updates, core config |
| **nix-darwin** | macOS packages, system settings, homebrew integration |
| **home-manager** | User config - shell, aliases, dotfiles, AI CLIs |
| **mac-app-util** | Stable app trampolines to preserve TCC permissions |

**Key Rule**: Use nixpkgs for everything. Homebrew is fallback only.

## What's Managed

| Category | Examples |
|----------|----------|
| CLI Tools | bat, delta, eza, fd, fzf, ripgrep, jq, htop |
| Development | nodejs, gh, claude-code, gemini-cli |
| GUI Apps | VS Code, Obsidian, Raycast, Bitwarden |
| macOS Settings | Dock, Finder, keyboard, trackpad, hot corners |
| AI CLI Permissions | 280+ auto-approved commands with security tiers |

## Dev Shells

Project-specific environments without polluting global state:

```bash
nix develop ~/.config/nix#python      # Python + pip + venv
nix develop ~/.config/nix#python-data # + pandas, numpy, jupyter
nix develop ~/.config/nix#js          # Node.js + npm/yarn/pnpm
nix develop ~/.config/nix#go          # Go + gopls + delve
nix develop ~/.config/nix#terraform   # Terraform/OpenTofu
```

See [shells/README.md](shells/README.md) for all available shells.

## Documentation

| File | Purpose |
|------|---------|
| [RUNBOOK.md](RUNBOOK.md) | Step-by-step operational procedures |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Detailed structure and module relationships |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and solutions |
| [CLAUDE.md](CLAUDE.md) | AI agent instructions |
| [docs/ANTHROPIC-ECOSYSTEM.md](docs/ANTHROPIC-ECOSYSTEM.md) | Claude Code integration reference |

## Contributing

Contributions welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for details.
The short version: open a PR, follow existing patterns, and I'll probably merge it.

## License

[Apache 2.0](LICENSE) - Use it, modify it, just keep the attribution.

---

*Built by a human, refined by AI, used by both.*
