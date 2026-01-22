# Trampoline App Permissions

This document describes the limitations and known issues with trampoline-style app launchers
in Nix on macOS, particularly regarding macOS TCC (Transparency, Consent, Control) permissions.

## Problem Overview

Trampoline apps create wrapper scripts in stable paths (e.g., `/Applications/Nix Apps/`) that
launch binaries from the Nix store. However, macOS TCC grants permissions to **specific binary
paths**, not wrapper scripts. This creates several user experience issues.

## Symptoms

1. **Generic Dock Icon**: Trampoline apps show a generic script icon in the dock instead of
   the application's actual icon

2. **Dual Dock Icons**: Launching a trampoline creates a NEW dock icon with the correct icon,
   pointing to `/nix/store/xxx-app/Applications/`

3. **Ephemeral Permissions**: App Management permissions are granted to Nix store paths, which
   change on every rebuild when package versions or dependencies update

4. **Repeated Permission Prompts**: After every `darwin-rebuild switch`, macOS prompts for
   permissions again because the binary path has changed

## Root Cause

macOS TCC (Transparency, Consent, Control) grants permissions to **specific binary paths**.
The trampoline pattern was designed to provide stable paths in `/Applications/Nix Apps/`, but
macOS still tracks (and grants permissions to) the underlying Nix store binary.

```text
Before rebuild: /nix/store/abc123-ghostty-1.2.3/...  ← Permission granted
After rebuild:  /nix/store/def456-ghostty-1.2.4/...  ← NEW path, needs permission again
```

Nix store paths are content-addressed. Any change to the package (version bump, dependency
update, rebuild) generates a new hash, resulting in a new path.

## Current Solution: copyApps

This repository migrated from `mac-app-util` trampolines to Home Manager's `copyApps` feature
for user-managed applications. This resolves the issue for apps managed by Home Manager.

### How copyApps Works

Instead of creating symlinks or trampolines, `copyApps` creates **real `.app` bundles** at
stable paths under `~/Applications/Home Manager Apps/`:

```nix
# In hosts/macbook-m4/home.nix
home.copyApps = true;
```

Result:

- Apps are copied to `~/Applications/Home Manager Apps/` (stable path)
- macOS TCC grants permissions to this stable path
- Permissions persist across `darwin-rebuild switch`
- Dock shows correct app icons

### Affected Apps

The following apps now use `copyApps` and no longer experience permission issues:

- Ghostty (terminal emulator)
- Visual Studio Code
- RapidAPI (removed from dock per #438)
- Postman (removed from dock per #438)
- Other user-level apps managed by Home Manager

## Remaining Limitations

### System-Level Packages

Apps installed via nix-darwin's `environment.systemPackages` still use trampolines because
`copyApps` is a Home Manager feature, not a nix-darwin feature.

System-level apps that may still experience permission issues:

- Bitwarden (managed via `environment.systemPackages`)
- OrbStack (managed via `environment.systemPackages`)
- Obsidian (managed via `environment.systemPackages`)

### Workarounds for System Apps

1. **Migrate to Home Manager**: Move apps to `home.packages` and enable `copyApps`

2. **Manual Permission Grants**: Re-grant permissions after each rebuild (tedious but works)

3. **Full Disk Access**: Add `/Applications/Nix Apps/` to Full Disk Access
   - **Security risk**: Grants broad permissions to all Nix apps
   - Not recommended for production systems

4. **Homebrew Casks**: For apps that need stable TCC permissions, consider using Homebrew
   casks instead of nixpkgs (Homebrew installs to `/Applications/` as real copies)

### Programmatic Permission Management (tccutil)

Apple provides `tccutil` for managing TCC permissions programmatically, but it has limitations:

- Requires Full Disk Access for the script running `tccutil`
- No official API for granting permissions (only resetting)
- Undocumented behavior and format changes between macOS versions

Example (untested):

```bash
# Reset permissions for an app (requires Full Disk Access)
sudo tccutil reset All /Applications/Nix Apps/Ghostty.app

# Grant permission (no official API, would require TCC database manipulation)
# Not recommended - TCC database format is undocumented and may change
```

## Testing Strategy

When adding new apps that require TCC permissions (screen recording, accessibility, camera,
microphone, etc.), test the following:

1. **Initial Launch**: Verify app launches and permission prompts appear
2. **Permission Grant**: Grant permissions via System Preferences → Privacy & Security
3. **Rebuild Test**: Run `darwin-rebuild switch` and verify:
   - Permissions persist (for `copyApps` apps)
   - Permissions must be re-granted (for trampoline apps)
4. **Dock Icon**: Check dock shows correct app icon (not generic script icon)

## Recommendations

1. **Prefer Home Manager with copyApps**: For user-level apps that need TCC permissions
2. **Use Homebrew for TCC-sensitive system apps**: If you can't use Home Manager
3. **Document permission requirements**: When adding new apps, note if they need TCC permissions
4. **Monitor upstream issues**: Watch for nix-darwin improvements to system-level app handling

## Related Issues

- [nix-darwin#1255](https://github.com/nix-darwin/nix-darwin/issues/1255) - LaunchDaemon bootstrap
- [home-manager#5189](https://github.com/nix-community/home-manager/issues/5189) - Trampoline apps
- [Issue #424](https://github.com/JacobPEvans/nix/issues/424) - Trampoline permissions invalidated on rebuild

## Additional Context

See `docs/boot-failure/root-cause.md` for related information about App Management permissions
and activation script failures.
