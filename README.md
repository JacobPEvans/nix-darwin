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
├── flake.nix                      # Entry point - defines inputs and system config
├── flake.lock                     # Locked versions (auto-managed)
├── darwin/
│   └── configuration.nix          # System packages, homebrew, macOS settings
├── home/
│   ├── home.nix                   # User shell config, aliases, AI CLI settings
│   ├── claude-permissions.nix     # Claude Code: allow list (277+ commands)
│   ├── claude-permissions-ask.nix # Claude Code: ask list (user-prompted)
│   ├── gemini-permissions.nix     # Gemini CLI: coreTools & excludeTools
│   ├── copilot-permissions.nix    # Copilot CLI: trusted_folders config
│   ├── vscode-copilot-settings.nix # VS Code Copilot: comprehensive settings
│   └── zsh/                       # Modular shell configuration files
├── CLAUDE.md                      # Instructions for AI agents
├── README.md                      # This file - quick reference
├── SETUP.md                       # Detailed setup and troubleshooting
├── CHANGELOG.md                   # Version history
└── PLANNING.md                    # Roadmap and future work
```

## Current Packages

**System packages** (darwin/configuration.nix):
- claude-code - Anthropic's AI coding assistant
- gemini-cli - Google's Gemini CLI
- gh - GitHub CLI
- git - Version control
- gnupg - GPG encryption
- nodejs_latest - Node.js runtime (latest stable)
- vim - Text editor

**User packages** (home/home.nix):
- VS Code - Code editor with declarative settings (including GitHub Copilot configuration)

**AI CLI Configurations** (fully Nix-managed):

1. **Claude Code** - Three-tier permission strategy
   - **Allow list**: 277+ safe auto-approved commands (claude-permissions.nix)
   - **Ask list**: Potentially dangerous operations requiring user approval (claude-permissions-ask.nix)
   - **Deny list**: 36 explicitly blocked dangerous operations
   - Config location: `~/.claude/settings.json`

2. **Gemini CLI** - coreTools/excludeTools model
   - **coreTools**: Mirrors Claude's allow list with ShellTool() syntax
   - **excludeTools**: Mirrors Claude's deny list
   - Config location: `~/.gemini/settings.json`
   - See: gemini-permissions.nix

3. **GitHub Copilot CLI** - Directory trust + runtime flags
   - **trusted_folders**: Approved project directories
   - **CLI flags**: Runtime tool permissions (--allow-tool, --deny-tool)
   - Config location: `~/.copilot/config.json`
   - See: copilot-permissions.nix

4. **VS Code GitHub Copilot** - Comprehensive editor integration
   - 50+ settings for completions, chat, agents, and security
   - Merged into VS Code settings.json
   - See: vscode-copilot-settings.nix

**Design philosophy**: All AI CLIs share the same categorized command structure and principle of least privilege, adapted to each tool's native format.

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
