# Permanent Fix

To prevent boot failures from recurring, add explicit LaunchDaemon bootstrap logic to your
nix-darwin configuration.

## Implementation

### Create modules/darwin/launchd-bootstrap.nix

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "[$(date '+%H:%M:%S')] [INFO] ============================================" >&2
    echo "[$(date '+%H:%M:%S')] [INFO] LaunchDaemon Bootstrap Check" >&2
    echo "[$(date '+%H:%M:%S')] [INFO] ============================================" >&2

    bootstrap_count=0
    already_loaded=0

    for plist in /Library/LaunchDaemons/org.nixos.*.plist /Library/LaunchDaemons/com.nix-darwin.*.plist; do
      if [ -f "$plist" ]; then
        # Extract label from plist, fallback to filename
        label=$(/usr/bin/plutil -extract Label raw "$plist" 2>/dev/null || basename "$plist" .plist)

        # Check if service is already loaded into launchd
        if ! /bin/launchctl print system/"$label" >/dev/null 2>&1; then
          echo "[$(date '+%H:%M:%S')] [INFO] Bootstrapping $label..." >&2
          if /bin/launchctl bootstrap system "$plist" 2>/dev/null; then
            ((bootstrap_count++))
            echo "[$(date '+%H:%M:%S')] [INFO] ✓ Successfully bootstrapped $label" >&2
          else
            echo "[$(date '+%H:%M:%S')] [WARN] Failed to bootstrap $label (may already be partially loaded)" >&2
          fi
        else
          ((already_loaded++))
          echo "[$(date '+%H:%M:%S')] [DEBUG] $label already loaded" >&2
        fi
      fi
    done

    if [ $bootstrap_count -gt 0 ]; then
      echo "[$(date '+%H:%M:%S')] [INFO] Bootstrapped $bootstrap_count service(s)" >&2
    fi
    if [ $already_loaded -gt 0 ]; then
      echo "[$(date '+%H:%M:%S')] [INFO] $already_loaded service(s) already loaded" >&2
    fi

    echo "[$(date '+%H:%M:%S')] [INFO] LaunchDaemon bootstrap complete" >&2
    echo "[$(date '+%H:%M:%S')] [INFO] ============================================" >&2
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

## Prevention Checklist

After implementing the fix, verify these to prevent recurrence:

- [ ] **LaunchDaemons are loaded**: `launchctl list | grep org.nixos` shows services
- [ ] **Activation script includes bootstrap**: Check your config imports `launchd-bootstrap.nix`
- [ ] **/run/current-system exists**: `ls -la /run/current-system` shows symlink
- [ ] **PATH is correct**: First entries include `/run/current-system/sw/bin`
- [ ] **Test a reboot**: Restart and verify everything works

## Post-Reboot Verification Script

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
