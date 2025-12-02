# Nix Configuration

Multi-host declarative system management using nix-darwin, home-manager, and flakes.

**This is a flakes-only configuration.** All nix commands use flakes. No channels.

## Hosts

| Host | Platform | Status | Description |
|------|----------|--------|-------------|
| **macbook-m4** | aarch64-darwin | Active | M4 Max MacBook Pro (primary) |
| **ubuntu-server** | x86_64-linux | Template | Ubuntu server (home-manager standalone) |
| **proxmox** | x86_64-linux | Template | Proxmox server (home-manager standalone) |
| **windows-workstation** | windows | Placeholder | Awaiting native Windows Nix support |

## How It Works

| Component | What It Does |
|-----------|--------------|
| **Determinate Nix** | Manages Nix itself - the daemon, updates, and core nix config |
| **nix-darwin** | Manages macOS packages, system settings, and homebrew integration |
| **home-manager** | Manages user config - shell, aliases, dotfiles |
| **nixpkgs** | The package repository - ALL packages come from here |

**Key Rule**: Use nixpkgs for everything. Homebrew is fallback only.

## Quick Start

```bash
# Rebuild after config changes
sudo darwin-rebuild switch --flake ~/.config/nix#default

# Search for a package
nix search nixpkgs <name>
```

See [RUNBOOK.md](RUNBOOK.md) for detailed procedures.

## Directory Structure

```
~/.config/nix/
├── flake.nix                      # Main entry point
├── flake.lock                     # Locked dependency versions
│
├── hosts/                         # Host-specific configurations
│   ├── macbook-m4/                # Active: M4 Max MacBook Pro
│   ├── ubuntu-server/             # Template: Ubuntu server
│   ├── proxmox/                   # Template: Proxmox server
│   └── windows-workstation/       # Placeholder: awaiting Windows Nix
│
├── modules/                       # Reusable configuration modules
│   ├── common/                    # Cross-platform packages
│   ├── darwin/                    # macOS system settings
│   │   └── dock/                  # Dock configuration
│   ├── linux/                     # Linux settings
│   └── home-manager/              # User environment (shell, git, vscode)
│       ├── ai-cli/                # AI CLI tool configurations
│       ├── permissions/           # AI CLI permission files
│       └── zsh/                   # Shell aliases and functions
│
├── lib/                           # Shared configuration variables
│
└── shells/                        # Development environment templates
    ├── python/                    # Basic Python
    ├── python-data/               # Python with data science tools
    ├── js/                        # Node.js
    ├── go/                        # Go
    └── terraform/                 # Terraform/OpenTofu
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full directory tree and module relationships.

## Current Packages

| Category | Packages |
|----------|----------|
| Core CLI | git, gnupg, vim |
| Modern CLI | bat, delta, eza, fd, fzf, htop, jq, ncdu, ripgrep, tldr, tree |
| Development | claude-code, gemini-cli, gh, mas, nodejs_latest |
| GUI | bitwarden-desktop, obsidian, raycast, vscode, zoom-us |
| Cloud (AWS) | awscli2, aws-vault |
| Linters | shellcheck, shfmt, markdownlint-cli2, actionlint, nixfmt-classic |

**Homebrew casks**: None - all packages managed via nixpkgs

## Documentation

| File | Purpose |
|------|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Detailed structure and module relationships |
| [RUNBOOK.md](RUNBOOK.md) | Step-by-step operational procedures |
| [SETUP.md](SETUP.md) | Initial setup and configuration decisions |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and solutions |
| [REFERENCES.md](REFERENCES.md) | External documentation links |
| [PLANNING.md](PLANNING.md) | Future roadmap |
| [CHANGELOG.md](CHANGELOG.md) | Completed work history |
