# Nix Darwin Configuration

Declarative macOS system management for M4 Max MacBook Pro.

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
darwin-rebuild switch --flake ~/.config/nix#default

# Search for a package
nix search nixpkgs <name>

# Update all flake inputs (nixpkgs, home-manager, etc.)
nix flake update ~/.config/nix

# Rollback if something breaks
darwin-rebuild --rollback
```

### First-Time Setup

If nix-darwin isn't initialized yet:

```bash
cd ~/.config/nix

# Build the system
nix build .#darwinConfigurations.default.system

# Activate (first time requires this path)
sudo ./result/sw/bin/darwin-rebuild switch --flake .#default
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
# List all generations
darwin-rebuild --list-generations

# Rollback to previous
darwin-rebuild --rollback

# Switch to specific generation
sudo /nix/var/nix/profiles/system-<N>-link/activate
```

## Directory Structure

```
~/.config/nix/
├── flake.nix              # Entry point - defines inputs and system config
├── flake.lock             # Locked versions (auto-managed)
├── darwin/
│   └── configuration.nix  # System packages, homebrew, macOS settings
├── home/
│   └── home.nix           # User shell config, aliases, functions
├── CLAUDE.md              # Instructions for AI agents
└── README.md              # This file
```

## Why Packages "Disappear"

If you install packages outside of nix (manual `brew install`, `npm -g`, etc.), they are NOT tracked by nix-darwin. After system updates or profile switches, these packages may vanish because:

1. They weren't in the nix store
2. PATH changes to prioritize nix-managed paths
3. Homebrew state isn't preserved by nix

**Solution**: Always add packages to `darwin/configuration.nix` and rebuild.

## Troubleshooting

### "error: attribute 'package-name' missing"
Package name differs in nixpkgs. Search for it:
```bash
nix search nixpkgs <partial-name>
```

### Changes not applying
1. Commit your changes to git (flakes require this)
2. Run: `darwin-rebuild switch --flake ~/.config/nix#default`
3. Open a new terminal

### "nix-darwin requires macOS ..." errors
Your system.stateVersion may need updating after macOS upgrades.

## Current Packages

Managed by nix-darwin (in `darwin/configuration.nix`):
- claude-code - Anthropic's AI coding assistant
- gemini-cli - Google's Gemini CLI
- gh - GitHub CLI
- git, gnupg, vim, nodejs

## Resources

- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [home-manager](https://nix-community.github.io/home-manager/)
- [Determinate Nix](https://determinate.systems/)
- [nixpkgs search](https://search.nixos.org/packages)
