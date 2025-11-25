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
darwin-rebuild switch --flake ~/.config/nix#default

# Search for a package
nix search nixpkgs <name>

# Update all flake inputs (nixpkgs, home-manager, etc.)
nix flake update ~/.config/nix

# Update Homebrew casks manually (auto-updates run every 24 hours)
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
3. Rebuild: `darwin-rebuild switch --flake ~/.config/nix#default`

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
├── flake.nix                  # Entry point - defines inputs and system config
├── flake.lock                 # Locked versions (auto-managed)
├── darwin/
│   └── configuration.nix      # System packages, homebrew, macOS settings
├── home/
│   ├── home.nix               # User shell config, aliases, Claude settings
│   ├── claude-permissions.nix # Claude Code auto-approved commands (allow list)
│   ├── claude-permissions-ask.nix # Claude Code user-prompted operations (ask list)
│   └── zsh/                   # Modular shell configuration files
├── CLAUDE.md                  # Instructions for AI agents
├── README.md                  # This file - quick reference
├── SETUP.md                   # Detailed setup and troubleshooting
├── CHANGELOG.md               # Version history
└── PLANNING.md                # Roadmap and future work
```

## Current Packages

**System packages** (darwin/configuration.nix):
- gemini-cli - Google's Gemini CLI
- gh - GitHub CLI
- git - Version control
- gnupg - GPG encryption
- nodejs_latest - Node.js runtime (latest stable)
- vim - Text editor

**Homebrew casks** (darwin/configuration.nix - auto-updated exceptions):
- claude-code - Anthropic's AI coding assistant (auto-updates every 24h via `brew autoupdate`)

**User packages** (home/home.nix):
- VS Code - Code editor with declarative settings
- Claude Code permissions - Three-tier strategy with allow/ask/deny lists
  - **Allow list**: 277+ safe auto-approved commands (claude-permissions.nix)
  - **Ask list**: Potentially dangerous operations requiring user approval (claude-permissions-ask.nix)
  - **Deny list**: 36 explicitly blocked dangerous operations

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
2. Run: `darwin-rebuild switch --flake ~/.config/nix#default`
3. Open a new terminal

### Package conflict (homebrew vs nix)
If `which <package>` shows `/opt/homebrew/bin` instead of `/run/current-system/sw/bin`:
```bash
# Remove homebrew version
sudo -u jevans brew uninstall <package>
# Verify nix version now found
which <package>
```

For detailed setup instructions and comprehensive troubleshooting, see [SETUP.md](SETUP.md).

## Resources

- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [home-manager](https://nix-community.github.io/home-manager/)
- [Determinate Nix](https://determinate.systems/)
- [nixpkgs search](https://search.nixos.org/packages)
