# Troubleshooting Guide

Common issues and solutions for this nix-darwin configuration.

## Table of Contents

- [Sudo Requirements](#sudo-requirements)
- [Quick Fixes](#quick-fixes)
- [Why Packages "Disappear"](#why-packages-disappear)
- [Package Management Issues](#package-management-issues)
- [Application Issues](#application-issues)
- [File Recovery](#file-recovery)
- [Related Documentation](#related-documentation)

---

## Sudo Requirements

Understanding when `sudo` is needed prevents permission issues.

### Commands That REQUIRE sudo

| Command | Why |
|---------|-----|
| `darwin-rebuild switch` | Modifies system-level configs in /etc, /run |
| `chown` on system files | Changing ownership requires root |
| `mv/rm` in /etc | System config directory |

**Correct usage**: See [RUNBOOK.md](RUNBOOK.md#everyday-commands) for the rebuild command.

### Commands That Should NOT Use sudo

| Command | Why |
|---------|-----|
| `nix build` | Builds to user-accessible store |
| `nix flake update` | Updates user's flake.lock |
| `git commit/push` | User's repository |
| Editing files in `~/.config/nix` | User's config directory |
| `brew install/uninstall` | Homebrew runs as user |

**Warning**: Running these as sudo creates root-owned files that break later operations.

### Fixing Root-Owned Files in User Directories

**Problem**: Files in `~/.config/nix` owned by root (usually from running editor as sudo).

**Solution**:

```bash
# Fix ownership of entire nix config directory
sudo chown -R $(whoami):staff ~/.config/nix

# Verify
ls -la ~/.config/nix
```

### AI CLI Tools and sudo

**Claude Code, Gemini CLI, etc.**:

- Should run as your user, NOT as sudo
- Running as sudo causes:
  - GPG signing failures (root can't access user's keychain)
  - Root-owned files in user directories
  - Home directory set to /var/root

**If you ran `sudo claude`**:

```bash
# Fix any root-owned files it created
sudo chown -R $(whoami):staff ~/.config/nix ~/.claude ~/.gitconfig
```

---

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
2. Rebuild (see [RUNBOOK.md](RUNBOOK.md#everyday-commands))
3. Open a new terminal

---

## Why Packages "Disappear"

Packages installed outside of nix (manual `brew install`, `npm -g`, etc.) are NOT tracked by nix-darwin.
After system updates or profile switches, these packages may vanish because:

1. They weren't in the nix store
2. PATH changes to prioritize nix-managed paths (`/run/current-system/sw/bin`)
3. Homebrew state isn't preserved by nix

**Solution**: Always add packages to `modules/darwin/common.nix` and rebuild.

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
   sudo -u <username> brew uninstall <package>
   # For GUI applications
   sudo -u <username> brew uninstall --cask <package>
   ```

5. **Verify nix version is now found**:

   ```bash
   which <package>  # Should show /run/current-system/sw/bin/<package>
   ```

### PATH Priority (Homebrew Before Nix)

**Problem**: `/opt/homebrew/bin` appears before `/run/current-system/sw/bin` in PATH.

**Correct PATH Order**:

```text
/Users/<username>/.nix-profile/bin
/etc/profiles/per-user/<username>/bin
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

### mac-app-util Build Failure (gitlab.common-lisp.net)

**Problem**: Build fails with errors like:

```text
tar: This does not look like a tar archive
do not know how to unpack source archive
```

**Cause**: `gitlab.common-lisp.net` has deployed Anubis anti-bot protection, which blocks Nix's automated source fetches for the `iterate` Common Lisp library.

**Solution**: The flake.nix already includes a workaround using a fork with GitHub mirrors:

```nix
mac-app-util = {
  url = "github:hraban/mac-app-util";
  inputs.cl-nix-lite.url = "github:r4v3n6101/cl-nix-lite/url-fix";
};
```

**Reference**: [mac-app-util issue #39](https://github.com/hraban/mac-app-util/issues/39)

### macOS TCC Permissions Reset After Rebuild

**Problem**: Camera, microphone, screen recording, or App Management permissions revoked after `darwin-rebuild switch`.

**Cause**: macOS TCC (Transparency, Consent, Control) tracks permissions by full file path.
Every Nix rebuild changes the `/nix/store/...` path, causing macOS to treat apps as "new"
and revoke permissions.

**Solution Architecture**:

This configuration uses multiple layers to ensure TCC permissions persist:

1. **mac-app-util trampolines**: Apps in `home.packages` get stable wrapper apps at `~/Applications/Home Manager Trampolines/` that don't change paths across rebuilds

2. **TCC-sensitive apps in home.packages**: Ghostty, Zoom, and OrbStack are in
   `home.packages` (see `hosts/macbook-m4/home.nix`) (not system packages) to get
   stable trampolines

3. **AssociatedBundleIdentifiers**: Auto-claude launchd agents are linked to Ghostty's bundle identifier so they can inherit its TCC permissions

4. **/bin/zsh fallback**: The system shell has a permanent path and can be granted Full Disk Access as a backup

### Setting Up TCC Permissions (One-Time)

After a fresh install or if permissions aren't working:

1. **Grant Full Disk Access to Ghostty trampoline**:
   - Open System Settings > Privacy & Security > Full Disk Access
   - Click the `+` button
   - Navigate to `~/Applications/Home Manager Trampolines/Ghostty.app`
   - Enable the toggle

2. **Grant Full Disk Access to /bin/zsh** (fallback):
   - In Full Disk Access, click `+`
   - Press `Cmd+Shift+G` and enter `/bin/zsh`
   - Enable the toggle

3. **Verify trampolines exist**:

```bash
# Check Home Manager trampolines
ls -la "~/Applications/Home Manager Trampolines/"
# Should show Ghostty.app, Zoom.app, OrbStack.app

# Check system apps (these do NOT get stable TCC)
ls -la /Applications/Nix\ Apps/
# Apps here change paths on rebuild - don't grant TCC to these
```

### Why This Works

- **Trampoline paths are stable**: `~/Applications/Home Manager Trampolines/Ghostty.app` never changes, even when the underlying Nix store path does
- **TCC stores permissions by path**: Once Ghostty trampoline has Full Disk Access, it persists across rebuilds
- **Launchd agents inherit permissions**: With `AssociatedBundleIdentifiers`, auto-claude agents inherit Ghostty's TCC permissions
- **/bin/zsh is immutable**: Apple's system shell path never changes, providing a reliable fallback

### Troubleshooting TCC Issues

**darwin-rebuild fails with permission errors**:

```bash
# Verify you're running from Ghostty (not Terminal.app)
echo $TERM_PROGRAM
# Should show: Ghostty

# If using Terminal.app, grant it Full Disk Access or switch to Ghostty
```

**auto-claude launchd agents fail with permission errors**:

```bash
# Check if agents have AssociatedBundleIdentifiers
find ~/Library/LaunchAgents -name 'com.claude.auto-claude-*.plist' -exec plutil -p {} + | grep Associated

# Verify Ghostty trampoline has Full Disk Access
# System Settings > Privacy & Security > Full Disk Access
```

**Permissions revoked after macOS update**:

macOS updates can sometimes reset TCC. Re-grant permissions to:

- `~/Applications/Home Manager Trampolines/Ghostty.app`
- `/bin/zsh`

### GPG "unsafe ownership" Warning

**Problem**: `gpg: WARNING: unsafe ownership on homedir '/Users/<username>/.gnupg'`

**Solution**:

```bash
# Fix ownership (replace <username> with your macOS username)
sudo chown -R <username>:staff ~/.gnupg

# Fix directory permissions (700)
sudo -u <username> find ~/.gnupg -type d -exec chmod 700 {} \;

# Fix file permissions (600)
sudo -u <username> find ~/.gnupg -type f -exec chmod 600 {} \;

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
