# nix-darwin

> macOS system configuration managed with nix-darwin and Nix flakes.

[![License][license-img]][license-link]

[![CI Gate][ci-gate-img]][ci-gate-link] [![Nix Build][nix-build-img]][nix-build-link] [![Markdown Lint][md-lint-img]][md-lint-link]

## What Is This?

A flakes-only nix-darwin configuration for M4 Max MacBook Pro. Manages system
packages, macOS settings, services, and LaunchAgents -- all declaratively.

**Part of a trio:**

| Repo | Purpose |
| ---- | ------- |
| **nix-darwin** (this repo) | macOS system config |
| [nix-ai](https://github.com/JacobPEvans/nix-ai) | AI coding tools (Claude, Gemini, Copilot, MCP) |
| [nix-home](https://github.com/JacobPEvans/nix-home) | Dev environment (git, zsh, VS Code, tmux) |

## Quick Start

```bash
# Rebuild after config changes (use the sa-drs alias)
sa-drs

# Search for a package
nix search nixpkgs <name>

# Rollback if something breaks
sudo darwin-rebuild --rollback
```

The `sa-drs` alias handles system activation automatically. See [RUNBOOK.md](RUNBOOK.md) for detailed procedures.

## What It Manages

- **Nix packages** via nixpkgs (preferred over Homebrew)
- **macOS system defaults** (Dock, Finder, keyboard, trackpad, energy)
- **Homebrew** (fallback for casks not in nixpkgs)
- **Security settings** (firewall, Gatekeeper, stealth mode)
- **LaunchAgents** via nix-darwin launchd modules
- **Activation scripts** with error tracking and recovery

See **[MANIFEST.md](MANIFEST.md)** for the complete package inventory.

## Directory Structure

```text
.
├── flake.nix                  # Main entry point
├── hosts/                     # Host-specific configurations
│   └── macbook-m4/            # Active M4 Max MacBook Pro
├── modules/                   # Reusable configuration modules
│   ├── common/                # Cross-platform packages
│   ├── darwin/                # macOS system settings
│   ├── home-manager/          # Activation and recovery
│   └── linux/                 # Linux-specific config
├── overlays/                  # Nixpkgs overlays
├── scripts/                   # Build and CI scripts
├── lib/                       # Shared configuration variables
└── tests/                     # Shell and integration tests
```

Full details in [ARCHITECTURE.md](ARCHITECTURE.md).

## Key Components

| Component | What It Does |
| --------- | ------------ |
| **Determinate Nix** | Manages Nix itself -- daemon, updates, core config |
| **nix-darwin** | macOS packages, system settings, Homebrew integration |
| **home-manager** | Activation recovery, config symlinks, and Raycast scripts |
| **mac-app-util** | Stable app trampolines to preserve TCC permissions |

**Key Rule**: Use nixpkgs for everything. Homebrew is fallback only.

## Documentation

| File | Purpose |
| ---- | ------- |
| [RUNBOOK.md](RUNBOOK.md) | Step-by-step operational procedures |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Detailed structure and module relationships |
| [MANIFEST.md](MANIFEST.md) | Complete inventory of packages and settings |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and solutions |
| [SETUP.md](SETUP.md) | Initial setup guide |
| [CLAUDE.md](CLAUDE.md) | AI agent instructions |

## Contributing

Contributions welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

[MIT](LICENSE)

---

*Built by a human, refined by AI, used by both.*

<!-- Badge references -->
[license-img]: https://img.shields.io/badge/License-MIT-blue.svg
[license-link]: LICENSE
[ci-gate-img]: https://github.com/JacobPEvans/nix-darwin/actions/workflows/ci-gate.yml/badge.svg
[ci-gate-link]: https://github.com/JacobPEvans/nix-darwin/actions/workflows/ci-gate.yml
[nix-build-img]: https://github.com/JacobPEvans/nix-darwin/actions/workflows/ci-nix.yml/badge.svg
[nix-build-link]: https://github.com/JacobPEvans/nix-darwin/actions/workflows/ci-nix.yml
[md-lint-img]: https://github.com/JacobPEvans/nix-darwin/actions/workflows/ci-markdownlint.yml/badge.svg
[md-lint-link]: https://github.com/JacobPEvans/nix-darwin/actions/workflows/ci-markdownlint.yml
