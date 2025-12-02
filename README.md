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

## Quick Reference

### Everyday Commands

```bash
# Rebuild after config changes (most common)
sudo darwin-rebuild switch --flake ~/.config/nix#default

# Search for a package
nix search nixpkgs <name>

# Rollback if something breaks
darwin-rebuild --rollback

# List all generations
darwin-rebuild --list-generations
```

### Keeping Packages Updated

Nix flakes pin exact versions for reproducibility. To get newer package versions:

```bash
# 1. Update flake.lock to latest nixpkgs
nix flake update --flake ~/.config/nix

# 2. Commit the updated lock file (required for flakes)
git -C ~/.config/nix add flake.lock
git -C ~/.config/nix commit -m "chore: update flake inputs"

# 3. Rebuild with new versions
sudo darwin-rebuild switch --flake ~/.config/nix#default
```

**Recommended frequency**: Weekly or when you notice outdated packages.

**If something breaks after update**:
```bash
git revert HEAD                    # Undo the flake.lock update
sudo darwin-rebuild switch --flake ~/.config/nix#default  # Rebuild with old versions
```

### Adding Packages

1. Search nixpkgs: `nix search nixpkgs <package>`
2. Edit `modules/darwin/common.nix`:
   ```nix
   environment.systemPackages = with pkgs; [
     new-package  # Description of what it does
   ];
   ```
3. Rebuild: `sudo darwin-rebuild switch --flake ~/.config/nix#default`

### Rollback & Recovery

```bash
# Rollback to previous generation
darwin-rebuild --rollback

# Switch to specific generation
sudo /nix/var/nix/profiles/system-<N>-link/activate
```

## Directory Structure

```
~/.config/nix/
├── flake.nix                      # Main entry point (macbook-m4 only)
├── flake.lock                     # Locked dependency versions
│
├── hosts/                         # Host-specific configurations
│   ├── macbook-m4/                # Active: M4 Max MacBook Pro
│   │   ├── default.nix            # Darwin system settings
│   │   └── home.nix               # User environment (Ollama, volumes)
│   ├── ubuntu-server/             # Template: Ubuntu server
│   │   ├── flake.nix              # Standalone flake for this host
│   │   ├── default.nix            # System notes (apt-managed)
│   │   └── home.nix               # home-manager config
│   ├── proxmox/                   # Template: Proxmox server
│   │   └── ...                    # Same structure as ubuntu-server
│   └── windows-workstation/       # Placeholder: awaiting Windows Nix
│       └── ...
│
├── modules/                       # Reusable configuration modules
│   ├── common/
│   │   └── packages.nix           # System-level packages for ALL platforms
│   ├── darwin/
│   │   └── common.nix             # macOS system packages, homebrew, settings
│   ├── linux/
│   │   └── common.nix             # Linux home-manager settings (XDG, packages)
│   └── home-manager/
│       ├── common.nix             # Cross-platform: shell, git, vscode
│       ├── ai-cli/                # AI CLI tool configurations
│       ├── permissions/           # AI CLI permission files
│       ├── git/                   # Git aliases and settings
│       ├── vscode/                # VS Code settings
│       └── zsh/                   # Shell aliases and functions
│
├── lib/                           # Shared configuration variables
│   ├── user-config.nix            # User info (name, email, GPG key)
│   ├── server-config.nix          # Server hostnames and settings
│   ├── security-policies.nix      # System-level security (git signing, etc.)
│   └── home-manager-defaults.nix  # Shared home-manager settings
│
├── shells/                        # Development environment templates
│   ├── python/                    # Basic Python development
│   ├── python-data/               # Python with pandas, numpy, jupyter
│   ├── js/                        # Node.js development
│   └── go/                        # Go development
│
├── CLAUDE.md                      # AI agent instructions
├── SETUP.md                       # Initial setup guide
├── TROUBLESHOOTING.md             # Common issues
├── CHANGELOG.md                   # Completed work history
├── PLANNING.md                    # Future roadmap
└── REFERENCES.md                  # External documentation links
```

## Current Packages

**System packages** (`modules/darwin/common.nix`):

| Category | Packages |
|----------|----------|
| Core CLI | git, gnupg, vim |
| Modern CLI | bat, delta, eza, fd, fzf, htop, jq, ncdu, ripgrep, tldr, tree |
| Development | claude-code, gemini-cli, gh, mas, nodejs_latest (ollama via manual install) |
| GUI | bitwarden-desktop, obsidian, raycast, vscode, zoom-us |

**System-level tools** (`modules/common/packages.nix` - all platforms):

| Category | Packages |
|----------|----------|
| Git hooks | pre-commit |
| Linters | shellcheck, shfmt, markdownlint-cli2, actionlint, nixfmt-classic |
| Security | bitwarden-cli |
| Cloud (AWS) | awscli2, aws-vault |

**Homebrew casks** (fallback only):
- None currently - all packages managed via nixpkgs

**AI CLI Configurations** (fully Nix-managed):

| Tool | Config File | Nix Source |
|------|-------------|------------|
| Claude Code | `~/.claude/settings.json` | `modules/home-manager/permissions/` |
| Gemini CLI | `~/.gemini/settings.json` | `modules/home-manager/permissions/` |
| Copilot CLI | `~/.copilot/config.json` | `modules/home-manager/permissions/` |
| VS Code Copilot | VS Code `settings.json` | `modules/home-manager/vscode/` |

All AI tools follow principle of least privilege with categorized command structures.

## Documentation

| File | Purpose |
|------|---------|
| [SETUP.md](SETUP.md) | Initial setup and configuration decisions |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and solutions |
| [REFERENCES.md](REFERENCES.md) | External documentation links |
| [PLANNING.md](PLANNING.md) | Future roadmap |
| [CHANGELOG.md](CHANGELOG.md) | Completed work history |

## Resources

See [REFERENCES.md](REFERENCES.md) for comprehensive documentation links including:
- nix-darwin and home-manager option references
- macOS system defaults documentation
- AI CLI tool configuration guides
- Package search resources
