# Nix Darwin Configuration

Declarative macOS system management for M4 Max MacBook Pro.

**This is a flakes-only configuration.** All nix commands use flakes. No channels.

## How It Works

| Component | What It Does |
|-----------|--------------|
| **Determinate Nix** | Manages Nix itself - the daemon, updates, and core nix config |
| **nix-darwin** | Manages macOS packages, system settings, and homebrew integration |
| **home-manager** | Manages user config - shell, aliases, dotfiles |
| **nixpkgs** | The package repository - ALL packages come from here |

**Key Rule**: Use nixpkgs for everything. Homebrew is fallback only (with auto-updates enabled).

## Quick Reference

### Everyday Commands

```bash
# Rebuild after config changes (most common)
sudo darwin-rebuild switch --flake ~/.config/nix#default

# Search for a package
nix search nixpkgs <name>

# Update all flake inputs (nixpkgs, home-manager, etc.)
nix flake update ~/.config/nix

# Update Homebrew casks (upgraded automatically on darwin-rebuild)
brew upgrade --cask

# Rollback if something breaks
darwin-rebuild --rollback

# List all generations
darwin-rebuild --list-generations
```

### Adding Packages

1. Search nixpkgs: `nix search nixpkgs <package>`
2. Edit `darwin/configuration.nix`:
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
├── flake.nix                      # Entry point - darwinConfigurations.default
├── flake.lock                     # Locked dependency versions (auto-managed)
├── darwin/
│   └── configuration.nix          # System packages, homebrew, macOS settings
├── home/
│   ├── home.nix                   # Main entry - imports all modules below
│   ├── ai-cli/                    # AI CLI configurations (home.file entries)
│   │   ├── claude.nix             # Claude Code settings + status line
│   │   ├── gemini.nix             # Gemini CLI settings
│   │   └── copilot.nix            # GitHub Copilot CLI config
│   ├── claude-permissions.nix     # Claude Code: allow/deny permission lists
│   ├── claude-permissions-ask.nix # Claude Code: user-prompted commands
│   ├── gemini-permissions.nix     # Gemini CLI: coreTools & excludeTools
│   ├── copilot-permissions.nix    # Copilot CLI: trusted_folders config
│   ├── vscode-settings.nix        # VS Code: general editor settings
│   ├── vscode-copilot-settings.nix # VS Code: GitHub Copilot settings
│   └── zsh/                       # Modular shell configuration files
├── CLAUDE.md                      # AI agent instructions (for Claude Code)
├── README.md                      # This file - project overview
├── SETUP.md                       # Initial setup and configuration decisions
├── TROUBLESHOOTING.md             # Common issues and solutions
├── CHANGELOG.md                   # Completed work history
└── PLANNING.md                    # Future roadmap and tasks
```

## Current Packages

**System packages** (darwin/configuration.nix):
- gemini-cli - Google's Gemini CLI
- gh - GitHub CLI
- git - Version control
- gnupg - GPG encryption
- nodejs_latest - Node.js runtime
- vim - Text editor
- vscode - Visual Studio Code editor

**Homebrew casks** (darwin/configuration.nix):
- claude-code - Anthropic's AI coding assistant (upgraded on `darwin-rebuild switch`)

**User configuration** (home/home.nix):
- VS Code settings merged from `vscode-settings.nix` and `vscode-copilot-settings.nix`
- Zsh shell with aliases and functions from `zsh/` directory

**AI CLI Configurations** (fully Nix-managed):

| Tool | Config File | Nix Source |
|------|-------------|------------|
| Claude Code | `~/.claude/settings.json` | `claude-permissions.nix`, `claude-permissions-ask.nix` |
| Gemini CLI | `~/.gemini/settings.json` | `gemini-permissions.nix` |
| Copilot CLI | `~/.copilot/config.json` | `copilot-permissions.nix` |
| VS Code Copilot | VS Code `settings.json` | `vscode-copilot-settings.nix` |

All AI tools follow principle of least privilege with categorized command structures.

## Why Packages "Disappear"

Packages installed outside of nix (manual `brew install`, `npm -g`, etc.) are NOT tracked by nix-darwin. After system updates or profile switches, these packages may vanish because:

1. They weren't in the nix store
2. PATH changes to prioritize nix-managed paths (`/run/current-system/sw/bin`)
3. Homebrew state isn't preserved by nix

**Solution**: Always add packages to `darwin/configuration.nix` or `home/home.nix` and rebuild.

## Quick Troubleshooting

### "error: attribute 'package-name' missing"
Package name differs in nixpkgs. Search for it:
```bash
nix search nixpkgs <partial-name>
```

### Changes not applying
1. Commit your changes to git (flakes require this)
2. Run: `sudo darwin-rebuild switch --flake ~/.config/nix#default`
3. Open a new terminal

### Package conflict (homebrew vs nix)
If `which <package>` shows `/opt/homebrew/bin` instead of `/run/current-system/sw/bin`:
```bash
# Remove homebrew version
sudo -u jevans brew uninstall <package>
# Verify nix version now found
which <package>
```

For comprehensive troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
For initial setup and configuration decisions, see [SETUP.md](SETUP.md).

## Resources

- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [home-manager](https://nix-community.github.io/home-manager/)
- [Determinate Nix](https://determinate.systems/)
- [nixpkgs search](https://search.nixos.org/packages)
