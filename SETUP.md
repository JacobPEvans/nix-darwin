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
sudo darwin-rebuild switch --flake ~/.config/nix#default
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

## Advanced Troubleshooting (2025-11-21)

### Issue: Duplicate Packages (Homebrew vs Nix)

**Problem**: After adding packages to nix-darwin, `which <package>` still shows homebrew versions from `/opt/homebrew/bin` instead of nix versions from `/run/current-system/sw/bin`.

**Root Cause**: Homebrew packages installed manually before nix-darwin was managing packages. PATH prioritizes `/opt/homebrew/bin` over `/run/current-system/sw/bin` in some shell configurations.

**Solution**:

1. **Verify the duplicate**:
   ```bash
   which claude  # Shows /opt/homebrew/bin/claude (wrong)
   ls -la /run/current-system/sw/bin/claude  # Verify nix version exists
   ```

2. **Check for homebrew installations**:
   ```bash
   brew list --formula  # List all formulas
   brew list --cask     # List all casks
   ```

3. **Backup important configurations**:
   - GPG keys: `~/.gnupg` (already user-owned, preserved automatically)
   - App settings: `~/Library/Application Support/<app>`
   - Create backup if needed: `cp -R ~/.config/app ~/backup/app-$(date +%Y-%m-%d)/`

4. **Remove homebrew versions as user** (not root):
   ```bash
   # For command-line tools (formulas)
   sudo -u jevans brew uninstall gemini-cli gnupg node

   # For GUI applications (casks)
   sudo -u jevans brew uninstall --cask claude-code
   ```

5. **Verify nix versions are now found**:
   ```bash
   which claude   # Should show /run/current-system/sw/bin/claude
   which gemini   # Should show /run/current-system/sw/bin/gemini
   which gpg      # Should show /run/current-system/sw/bin/gpg
   which node     # Should show /run/current-system/sw/bin/node
   ```

6. **Test functionality**:
   ```bash
   claude --version
   gemini --version
   gpg --list-keys  # Verify keys still accessible
   node --version
   ```

**Packages Successfully Migrated (2025-11-21)**:
- claude-code: 2.0.49 (homebrew cask) → 2.0.44 (nix)
- gemini-cli: 0.16.0 (homebrew) → 0.15.3 (nix)
- gnupg: 2.4.8 (homebrew) → 2.4.8 (nix)
- node: 25.2.1 (homebrew) → 24.11.1 (nix, nodejs_latest)

### Issue: GPG "unsafe ownership" Warning

**Problem**: After migrating GPG from homebrew to nix, `gpg` shows warning:
```
gpg: WARNING: unsafe ownership on homedir '/Users/jevans/.gnupg'
```

**Root Cause**: Directory permissions or extended attributes on `~/.gnupg` not strict enough for GPG's security requirements.

**Solution**:
```bash
# Fix ownership
sudo chown -R jevans:staff ~/.gnupg

# Fix directory permissions (700)
sudo -u jevans find ~/.gnupg -type d -exec chmod 700 {} \;

# Fix file permissions (600)
sudo -u jevans find ~/.gnupg -type f -exec chmod 600 {} \;

# Verify GPG works
gpg --list-keys
```

**Note**: GPG keys and trust database in `~/.gnupg` are preserved automatically during package transitions since they're in the home directory, not managed by package managers.

### Issue: home.nix File Became Empty

**Problem**: After rebuild, `home/home.nix` was truncated to 0 bytes, losing all configuration.

**Root Cause**: Unknown (possibly editor or build process issue).

**Solution**:

1. **Check for backup files**:
   ```bash
   ls -la ~/.config/nix/home/
   # Look for home.nix~ or home.nix.backup
   ```

2. **Restore from backup**:
   ```bash
   cp ~/.config/nix/home/home.nix~ ~/.config/nix/home/home.nix
   ```

3. **Or restore from git**:
   ```bash
   cd ~/.config/nix
   git restore home/home.nix
   # Or from specific commit:
   git show HEAD:home/home.nix > home/home.nix
   ```

**Prevention**: Always commit changes before rebuilding. Flakes require git tracking anyway, so regular commits provide automatic recovery points.

### Issue: VS Code userSettings Deprecation

**Problem**: Build shows warning:
```
warning: jevans profile: The option `programs.vscode.userSettings' defined in `<unknown-file>'
has been renamed to `programs.vscode.profiles.default.userSettings'.
```

**Solution**: Update `home/home.nix`:

```nix
# OLD (deprecated):
programs.vscode = {
  enable = true;
  userSettings = {
    "editor.formatOnSave" = true;
  };
};

# NEW (correct):
programs.vscode = {
  enable = true;
  profiles.default.userSettings = {
    "editor.formatOnSave" = true;
  };
};
```

### Issue: PATH Priority (Homebrew Before Nix)

**Problem**: `echo $PATH` shows `/opt/homebrew/bin` before `/run/current-system/sw/bin`, causing homebrew packages to shadow nix packages.

**Expected PATH Order**:
```
/opt/homebrew/bin            ← WRONG: Should not be first
/run/current-system/sw/bin   ← Nix packages should come first
```

**Correct PATH Order**:
```
/Users/jevans/.nix-profile/bin
/etc/profiles/per-user/jevans/bin
/run/current-system/sw/bin          ← Nix packages here
/nix/var/nix/profiles/default/bin
/opt/homebrew/bin                   ← Homebrew fallback only
```

**Solution**:

1. Check `~/.zprofile` for homebrew shellenv initialization
2. Remove or comment out manual homebrew PATH additions
3. Let nix-darwin manage PATH via `/etc/zshenv`
4. Open new terminal to get updated PATH

**Why This Happens**: macOS's `/etc/zshenv` (managed by nix-darwin) sets up nix paths, but `~/.zprofile` (sourced later) may add homebrew first, overriding the correct order.

## Resources
- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [Home Manager manual](https://nix-community.github.io/home-manager/)
- [Determinate Nix](https://determinate.systems/nix-installer/)
