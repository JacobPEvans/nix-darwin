# Nix Boot Failure Recovery Guide

Complete guide for diagnosing and recovering from nix-darwin boot failures where the system
appears broken after restart (empty PATH, missing commands, etc.).

## Table of Contents

- [Symptoms](#symptoms)
- [Quick Recovery](#quick-recovery)
- [Root Cause Explanation](#root-cause-explanation)
- [Diagnostic Commands](#diagnostic-commands)
- [Permanent Fix](#permanent-fix)
- [Prevention Checklist](#prevention-checklist)

---

## Symptoms

After a system restart, you may experience:

| Symptom | What You'll See |
|---------|-----------------|
| Empty PATH | `echo $PATH` shows nothing or only `/usr/bin:/bin` |
| Commands not found | `darwin-rebuild: command not found` |
| Missing symlink | `ls /run/current-system` returns "No such file or directory" |
| Nix commands fail | `nix` works but `darwin-rebuild` doesn't |
| Shell looks broken | zsh completions missing, oh-my-zsh not loading |

**Quick Check**: Run this to confirm the issue:

```bash
ls -la /run/current-system
# If this returns "No such file or directory", your activation didn't run at boot
```

---

## Quick Recovery

### Step 1: Bootstrap Missing LaunchDaemons

The root cause is that nix-darwin's launchd services weren't loaded at boot. Load them manually:

```bash
sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.darwin-store.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.activate-system.plist
```

**Expected output**: No output means success. If you see an error like "service already loaded",
that's also fine.

**Verify they're loaded**:

```bash
launchctl print system/org.nixos.activate-system
# Should show service details, NOT "Could not find service"
```

### Step 2: Run Activation

```bash
sudo /nix/var/nix/profiles/system/activate
```

**Expected output**: You'll see activation messages like:

```text
setting up /etc...
setting up launchd services...
```

**If activation fails**, see [Activation Failures](#activation-failures) below.

### Step 3: Start Fresh Shell

```bash
exec zsh
```

### Step 4: Verify Recovery

```bash
# Check PATH is populated
echo $PATH | tr ':' '\n' | head -5
# Should show /run/current-system/sw/bin and other Nix paths

# Check darwin-rebuild works
which darwin-rebuild
# Should show /run/current-system/sw/bin/darwin-rebuild

# Check system symlink exists
ls -la /run/current-system
# Should show symlink to /nix/store/...

# Check launchd services
launchctl list | grep org.nixos
# Should show org.nixos.activate-system and org.nixos.darwin-store
```

---

## Root Cause Explanation

### Why This Happens

On macOS with Determinate Nix + nix-darwin, there are two sets of launchd services:

| Service Owner | Services | Boot Behavior |
|---------------|----------|---------------|
| **Determinate Nix** | `systems.determinate.nix-daemon`, `systems.determinate.nix-store` | **Works** - bootstrapped during Determinate Nix installation |
| **nix-darwin** | `org.nixos.activate-system`, `org.nixos.darwin-store` | **May fail** - requires explicit bootstrap |

The `org.nixos.activate-system` service is responsible for:

1. Creating `/run/current-system` symlink
2. Running activation scripts
3. Setting up `/etc/static/*` symlinks
4. Configuring shell environment variables

If this service doesn't run at boot, your entire Nix environment appears broken.

### Why nix-darwin Services Don't Auto-Load

On modern macOS (Ventura+), LaunchDaemons in `/Library/LaunchDaemons/` need to be explicitly
**bootstrapped** into launchd using `launchctl bootstrap system <plist>`. Simply placing a
plist file in the directory is not enough.

Determinate Nix's installer runs this bootstrap step. nix-darwin's activation may skip it
if:

1. The services were already registered (but got unloaded somehow)
2. Activation was interrupted before the launchctl step
3. macOS's launchd cache got corrupted

### The Chain of Failure

```text
Boot
  └─→ /nix/store mounted (Determinate Nix - works)
  └─→ org.nixos.activate-system should run (nix-darwin - FAILS)
        └─→ /run/current-system symlink NOT created
              └─→ Shell config can't find NIX_PROFILES
                    └─→ PATH is empty
                          └─→ All Nix commands "not found"
```

---

## Diagnostic Commands

### Check What's Broken

```bash
# Check if /run/current-system exists
ls -la /run/current-system 2>&1
# "No such file or directory" = activation didn't run

# Check if services are loaded
launchctl list | grep -E "(nix|darwin)"
# Should show org.nixos.activate-system with exit code

# Check if plists exist
ls -la /Library/LaunchDaemons/org.nixos.*.plist
# Should show activate-system.plist and darwin-store.plist

# Check if plists are valid
plutil -lint /Library/LaunchDaemons/org.nixos.activate-system.plist
# Should say "OK"

# Check service status in detail
sudo launchctl print system/org.nixos.activate-system
# "Could not find service" = not loaded
# Detailed output = loaded but may have failed
```

### Check What's Working

```bash
# Determinate Nix daemon (should be running)
launchctl list | grep determinate
# Should show systems.determinate.nix-daemon with PID

# Nix store is mounted
mount | grep nix
# Should show /dev/disk... on /nix

# System profile exists
ls -la /nix/var/nix/profiles/system
# Should show symlink to system-XXX-link
```

### Check Boot Logs

```bash
# Look for activation attempts at boot
log show --last boot --predicate 'eventMessage CONTAINS "activate"' | head -20

# Check launchd errors
log show --last boot --predicate 'subsystem == "com.apple.launchd"' | grep -i nix
```

---

## Activation Failures

If `sudo /nix/var/nix/profiles/system/activate` fails:

### Error: "Unexpected files in /etc"

```text
error: Unexpected files in /etc, aborting activation
The following files have unrecognized content and would be overwritten:
  /etc/zshrc
  /etc/bashrc
```

**Fix**: Rename conflicting files:

```bash
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
# Then retry activation
sudo /nix/var/nix/profiles/system/activate
```

### Error: "homebrew installed required"

```text
error: Using the homebrew module requires homebrew installed
```

**Fix**: Install Homebrew first:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Then retry activation
sudo /nix/var/nix/profiles/system/activate
```

### Error: Permission denied

```text
error: permission denied when trying to update apps
```

**Fix**: Grant terminal Full Disk Access:

1. Open System Settings > Privacy & Security > Full Disk Access
2. Add your terminal app (Ghostty, Terminal.app, etc.)
3. Retry activation

### Error: /etc/ssh/authorized_keys.d exists

```text
error: /etc/ssh/authorized_keys.d exists, aborting activation
```

**Fix**: Remove the directory after reviewing its contents:

```bash
ls -la /etc/ssh/authorized_keys.d  # Review contents
sudo rm -rf /etc/ssh/authorized_keys.d
# Then retry activation
sudo /nix/var/nix/profiles/system/activate
```

---

## Permanent Fix

To prevent this issue from recurring, add explicit LaunchDaemon bootstrap logic to your
nix-darwin configuration.

### Create modules/darwin/launchd-bootstrap.nix

```nix
{ config, lib, pkgs, ... }:

{
  # Ensure nix-darwin LaunchDaemons are bootstrapped into launchd
  # This fixes the issue where services exist as plists but aren't loaded
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "Ensuring nix-darwin LaunchDaemons are bootstrapped..."

    for plist in /Library/LaunchDaemons/org.nixos.*.plist /Library/LaunchDaemons/com.nix-darwin.*.plist; do
      if [ -f "$plist" ]; then
        label=$(/usr/bin/plutil -extract Label raw "$plist" 2>/dev/null || basename "$plist" .plist)

        # Check if service is already loaded
        if ! /bin/launchctl print system/"$label" >/dev/null 2>&1; then
          echo "  Bootstrapping $label..."
          /bin/launchctl bootstrap system "$plist" 2>/dev/null || true
        fi
      fi
    done

    echo "LaunchDaemon bootstrap complete."
  '';
}
```

### Import in Your Host Configuration

In `hosts/<hostname>/default.nix`:

```nix
{
  imports = [
    # ... other imports ...
    ../../modules/darwin/launchd-bootstrap.nix
  ];
}
```

### Rebuild

```bash
cd ~/.config/nix  # or your nix-config path
git add modules/darwin/launchd-bootstrap.nix
git commit -m "fix: ensure LaunchDaemons are bootstrapped during activation"
sudo darwin-rebuild switch --flake .
```

---

## Prevention Checklist

After recovery, verify these to prevent recurrence:

- [ ] **LaunchDaemons are loaded**: `launchctl list | grep org.nixos` shows services
- [ ] **Activation script includes bootstrap**: Check your config imports `launchd-bootstrap.nix`
- [ ] **/run/current-system exists**: `ls -la /run/current-system` shows symlink
- [ ] **PATH is correct**: First entries include `/run/current-system/sw/bin`
- [ ] **Test a reboot**: Restart and verify everything works

### Post-Reboot Verification Script

Save this as `~/.local/bin/verify-nix-boot`:

```bash
#!/bin/bash
# Verify nix-darwin boot was successful

echo "=== Nix Boot Verification ==="

# Check 1: /run/current-system
if [ -L /run/current-system ]; then
  echo "✅ /run/current-system exists"
else
  echo "❌ /run/current-system MISSING - run recovery steps"
  exit 1
fi

# Check 2: LaunchDaemons loaded
if launchctl list | grep -q "org.nixos.activate-system"; then
  echo "✅ org.nixos.activate-system loaded"
else
  echo "❌ org.nixos.activate-system NOT loaded"
  exit 1
fi

# Check 3: darwin-rebuild available
if command -v darwin-rebuild &> /dev/null; then
  echo "✅ darwin-rebuild in PATH"
else
  echo "❌ darwin-rebuild NOT in PATH"
  exit 1
fi

# Check 4: PATH includes nix paths
if echo "$PATH" | grep -q "/run/current-system/sw/bin"; then
  echo "✅ PATH includes /run/current-system/sw/bin"
else
  echo "❌ PATH missing /run/current-system/sw/bin"
  exit 1
fi

echo ""
echo "All checks passed! Nix environment is healthy."
```

---

## Related Documentation

- [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) - General troubleshooting guide
- [RUNBOOK.md](../RUNBOOK.md) - Common commands and procedures
- [docs/ACTIVATION-SCRIPTS-RULES.md](ACTIVATION-SCRIPTS-RULES.md) - Rules for writing activation scripts
- [docs/ACTIVATION-EXIT-CODES.md](ACTIVATION-EXIT-CODES.md) - Understanding activation exit codes

---

## Incident Log

### 2025-12-31: Full Environment Failure After Restart

**Symptoms**:

- PATH completely empty after system restart
- `darwin-rebuild: command not found`
- `/run/current-system` did not exist
- All nix-darwin LaunchDaemons (`org.nixos.*`) were not loaded

**Root Cause**:

nix-darwin's LaunchDaemon plists existed in `/Library/LaunchDaemons/` but were never
`launchctl bootstrap`ed into launchd. Determinate Nix's services (`systems.determinate.*`)
worked fine because they're bootstrapped during Determinate Nix installation.

**Resolution**:

1. Manually bootstrapped services: `sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.activate-system.plist`
2. Ran activation: `sudo /nix/var/nix/profiles/system/activate`
3. Started new shell: `exec zsh`

**Prevention**:

Created `modules/darwin/launchd-bootstrap.nix` to ensure services are always bootstrapped
during activation.
