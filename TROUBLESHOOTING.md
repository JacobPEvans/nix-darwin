# Troubleshooting Guide

Common issues and solutions for this nix-darwin configuration.

## Quick Fixes

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

Ensure backup extension is set in flake.nix:
```nix
home-manager.backupFileExtension = "backup";
```

### "error: attribute 'package-name' missing"

Package name differs in nixpkgs. Search for it:
```bash
nix search nixpkgs <partial-name>
```

### Changes not applying

1. Commit your changes to git (flakes require this)
2. Run: `sudo darwin-rebuild switch --flake ~/.config/nix#default`
3. Open a new terminal

---

## Package Management Issues

### Duplicate Packages (Homebrew vs Nix)

**Problem**: `which <package>` shows `/opt/homebrew/bin` instead of `/run/current-system/sw/bin`.

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

3. **Backup important configurations** (GPG keys, app settings):
   ```bash
   cp -R ~/.config/app ~/backup/app-$(date +%Y-%m-%d)/
   ```

4. **Remove homebrew versions as user** (not root):
   ```bash
   # For command-line tools
   sudo -u jevans brew uninstall <package>
   # For GUI applications
   sudo -u jevans brew uninstall --cask <package>
   ```

5. **Verify nix version is now found**:
   ```bash
   which <package>  # Should show /run/current-system/sw/bin/<package>
   ```

### PATH Priority (Homebrew Before Nix)

**Problem**: `/opt/homebrew/bin` appears before `/run/current-system/sw/bin` in PATH.

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

---

## Application Issues

### GPG "unsafe ownership" Warning

**Problem**: `gpg: WARNING: unsafe ownership on homedir '/Users/jevans/.gnupg'`

**Solution**:
```bash
# Fix ownership
sudo chown -R jevans:staff ~/.gnupg

# Fix directory permissions (700)
sudo -u jevans find ~/.gnupg -type d -exec chmod 700 {} \;

# Fix file permissions (600)
sudo -u jevans find ~/.gnupg -type f -exec chmod 600 {} \;

# Verify
gpg --list-keys
```

### VS Code userSettings Deprecation

**Problem**: Warning about `programs.vscode.userSettings` being renamed.

**Solution**: Update `home/home.nix`:
```nix
# OLD (deprecated):
programs.vscode.userSettings = { ... };

# NEW (correct):
programs.vscode.profiles.default.userSettings = { ... };
```

---

## File Recovery

### home.nix File Became Empty

**Problem**: Configuration file truncated to 0 bytes.

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
   ```

**Prevention**: Always commit changes before rebuilding.

---

## Related Documentation

- [README.md](README.md) - Quick reference and commands
- [SETUP.md](SETUP.md) - Initial setup and configuration decisions
