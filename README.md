# Nix Darwin Configuration

Declarative macOS system management using nix-darwin and home-manager for M4 Max MacBook Pro.

## Overview

This repository contains a minimal, production-ready nix-darwin configuration that provides:

- **Declarative System Configuration**: macOS system settings managed via Nix
- **User Environment Management**: Shell configuration, aliases, and dotfiles via home-manager
- **Reproducible Builds**: Flake-based configuration with locked dependencies
- **Profile Switching Foundation**: Architecture supports multiple system profiles
- **Version Control**: All configuration tracked in git with conventional commits

## Quick Start

### Prerequisites

- macOS on Apple Silicon (aarch64-darwin)
- Nix with flakes enabled (Determinate Nix installer recommended)
- Git

### Build and Activate

```bash
# Navigate to configuration directory
cd ~/.config/nix

# Build the system configuration
nix build .#darwinConfigurations.default.system

# Activate the configuration (requires sudo)
sudo ./result/sw/bin/darwin-rebuild switch --flake .#default

# Or use darwin-rebuild directly (after first activation)
darwin-rebuild switch --flake ~/.config/nix#default
```

### Verify Installation

```bash
# Check darwin-rebuild version
darwin-rebuild --version

# Check home-manager version
home-manager --version

# Verify system packages
which git gh vim

# Test shell aliases
ll  # Enhanced ls with timestamps
```

## Architecture

### Directory Structure

```
~/.config/nix/
├── flake.nix                 # Main entry point, defines system configurations
├── flake.lock                # Locked dependency versions for reproducibility
├── darwin/
│   └── configuration.nix     # System-level macOS settings and packages
├── home/
│   └── home.nix             # User environment (shell, aliases, functions)
├── backup/                   # Archived previous configurations (git-ignored)
├── SETUP.md                  # Comprehensive setup guide and troubleshooting
├── CHANGELOG.md              # Version history and completed changes
├── PLANNING.md               # Current status and remaining tasks
└── README.md                 # This file
```

### Current Configuration

**System Packages** (darwin/configuration.nix):
- git - Version control
- gh - GitHub CLI for PR management
- vim - Text editor

**Shell Configuration** (home/home.nix):
- Zsh with custom aliases (ll, llt, lls, tgz, python, pip)
- Custom functions (gitmd - merge and delete branches)
- Automatic session logging to ~/logs/
- Automatic .DS_Store cleanup

**Key Features**:
- Determinate Nix compatibility (nix.enable = false)
- Documentation builds disabled for faster rebuilds
- Automatic file backups via home-manager
- Single default profile (foundation for future multi-profile support)

## System Management

### Updating Configuration

1. Edit configuration files (`darwin/configuration.nix`, `home/home.nix`)
2. Commit changes to git (required for flakes)
3. Rebuild and switch: `darwin-rebuild switch --flake ~/.config/nix#default`

### Adding Packages

Add packages to `darwin/configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  git
  gh
  vim
  # Add new packages here
];
```

### Rollback

Nix-darwin maintains system generations for easy rollback:

```bash
# List available generations
darwin-rebuild --list-generations

# Switch to previous generation
darwin-rebuild --rollback

# Switch to specific generation
sudo /nix/var/nix/profiles/system-<generation>-link/activate
```

## Documentation

- **[SETUP.md](./SETUP.md)**: Detailed setup guide, issues solved, and troubleshooting
- **[CHANGELOG.md](./CHANGELOG.md)**: Version history and completed changes
- **[PLANNING.md](./PLANNING.md)**: Current status and future roadmap

## Current Status

**✅ Completed:**
- Minimal nix-darwin setup with Determinate Nix compatibility
- Home-manager integration with zsh configuration migration
- GitHub CLI (gh) installation for PR workflow automation
- Comprehensive documentation and issue tracking

**🚧 In Progress:**
- GitHub CLI authentication setup
- Pull request review and feedback implementation
- Additional documentation standards compliance

**📋 Planned:**
- Profile switching (work, dev, ai-research, minimal)
- Essential application installation (Obsidian, Raycast, Brave, Slack)
- macOS system preferences configuration
- Homebrew migration to nix-darwin management

See [PLANNING.md](./PLANNING.md) for detailed roadmap.

## Resources

- [nix-darwin Documentation](https://github.com/LnL7/nix-darwin)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Determinate Nix Installer](https://determinate.systems/nix-installer/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)

## Contributing

This is a personal system configuration, but follows best practices from:
- [ai-assistant-instructions](https://github.com/JacobPEvans/ai-assistant-instructions) - AI-assisted development workflows
- [Conventional Commits](https://www.conventionalcommits.org/) - Commit message standards
- [Keep a Changelog](https://keepachangelog.com/) - Changelog format

## License

Personal configuration - use at your own risk. No warranty provided.
