# Nix Darwin Setup - M4 Max MacBook Pro

## Overview
Minimal nix-darwin configuration with home-manager for macOS system management.

## Setup Summary
- **Date**: 2025-11-19
- **Machine**: MacBook Pro M4 Max (128GB RAM)
- **Nix Version**: 2.31.2 (Determinate Nix installer)
- **Darwin**: nix-darwin 25.05
- **Home Manager**: 25.05

## Configuration Structure
```
~/.config/nix/
├── flake.nix                 # Main flake with default profile
├── flake.lock                # Locked dependencies
├── darwin/
│   └── configuration.nix     # System-level configuration
├── home/
│   └── home.nix             # User-level home-manager config
└── backup/                   # Old Linux-based config (archived)
```

## Issues Solved

### 1. Determinate Nix Compatibility
**Problem**: nix-darwin's Nix management conflicts with Determinate Nix installer.

**Solution**: Disabled nix-darwin's Nix management in `darwin/configuration.nix`:
```nix
nix.enable = false;
```

**Why**: Determinate Nix manages its own daemon. Setting `nix.enable = false` allows nix-darwin to manage everything except Nix itself.

### 2. Documentation Build Warnings
**Problem**: Warning about `builtins.toFile` referencing store paths without proper context.

**Solution**: Disabled documentation building:
```nix
documentation.enable = false;
```

**Why**: The warning comes from upstream nix-darwin/home-manager documentation generation. Disabling documentation prevents the warning and speeds up builds.

### 3. Existing System Files Conflict
**Problem**: `/etc/bashrc` already existed and blocked activation.

**Solution**: Renamed existing file to `.before-nix-darwin` suffix:
```bash
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
```

**Why**: nix-darwin needs to manage system files. The backup allows reverting if needed.

### 4. Home Manager File Conflicts
**Problem**: Existing `~/.zshrc` prevented home-manager from managing it.

**Solution**: Added backup extension in `flake.nix`:
```nix
home-manager.backupFileExtension = "backup";
```

**Why**: Automatically backs up existing files before home-manager takes control (creates `.zshrc.backup`).

### 5. Nix Settings Warnings
**Problem**: Warnings about unknown settings `eval-cores` and `lazy-trees`.

**Solution**: None required - warnings are harmless.

**Why**: Determinate Nix config uses forward-compatible settings for newer Nix versions. Current version (2.31.2) simply ignores them. No functionality is affected.

## What Was Migrated

### From ~/.zshrc to home-manager
All configuration moved to `home/home.nix`:

**Aliases**:
- `ll`, `llt`, `lls` - Enhanced ls with date formatting
- `python`, `pip` - Python 3.12 shortcuts
- `tgz` - Mac-friendly tar compression

**Functions**:
- `gitmd()` - Git merge and delete branch

**Environment**:
- Session logging to ~/logs/
- .DS_Store cleanup
- Tab width settings

## Usage

### Rebuild System
```bash
cd ~/.config/nix
nix build .#darwinConfigurations.default.system
sudo ./result/sw/bin/darwin-rebuild switch --flake ~/.config/nix#default
```

### Or use darwin-rebuild directly (after first activation)
```bash
darwin-rebuild switch --flake ~/.config/nix#default
```

### Check Current Configuration
```bash
darwin-rebuild --version
home-manager --version
```

## Future Enhancements
- [ ] Add work profile for profile switching
- [ ] Add essential applications (Obsidian, Raycast, Brave, Slack)
- [ ] Configure AI research profile with APFS volume for models
- [ ] Replace Homebrew with nix-darwin's Homebrew management
- [ ] Add dev profile with language runtimes

## Key Decisions

1. **Clean slate approach**: Started minimal instead of adapting Linux-based config
2. **Determinate Nix**: Using Determinate installer instead of official Nix
3. **Documentation disabled**: Cleaner builds, faster compilation
4. **File backups**: All existing files backed up automatically
5. **Single profile initially**: Testing with default profile before adding complexity

## Lessons Learned

1. **Determinate Nix conflicts** with nix-darwin's Nix management - disable with `nix.enable = false`
2. **Always backup files** - home-manager and nix-darwin can clobber existing configs
3. **Unknown setting warnings are harmless** - forward compatibility doesn't break functionality
4. **Flakes require git tracking** - all files must be `git add`ed before building
5. **Permissions matter** - some git objects created by Nix need ownership fixes

## Troubleshooting

### "command not found: nix"
Source the Nix daemon script:
```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Git permission errors during build
Fix ownership of .git directory:
```bash
sudo chown -R $(whoami):staff ~/.config/nix/.git
```

### Activation fails with "files in the way"
Rename conflicting files with `.before-nix-darwin` suffix:
```bash
sudo mv /etc/conflicting-file /etc/conflicting-file.before-nix-darwin
```

### Home-manager activation fails
Add backup extension to flake configuration (already done in this setup).

## Resources
- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [Home Manager manual](https://nix-community.github.io/home-manager/)
- [Determinate Nix](https://determinate.systems/nix-installer/)
