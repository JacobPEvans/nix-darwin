# Ensure nix-darwin LaunchDaemons are bootstrapped into launchd
#
# WORKAROUND for upstream issue: https://github.com/nix-darwin/nix-darwin/issues/1255
#
# Problem: nix-darwin uses deprecated `launchctl load` commands which don't
# reliably persist across reboots on modern macOS (Ventura/Sonoma). After
# macOS updates or certain reboots, launchd "forgets" about services that
# were loaded with the legacy API.
#
# The recommended fix (per Apple) is to use `launchctl bootstrap` with explicit
# domain targets, but nix-darwin hasn't implemented this yet.
#
# This module works around the issue by:
# 1. Running `launchctl bootstrap` during every activation (idempotent)
# 2. Only bootstrapping services that aren't already loaded
# 3. Using the newer API that macOS prefers
#
# Once nix-darwin fixes #1255 upstream, this module can be removed.
#
# See: docs/boot-failure/ (from repository root) for full documentation

{
  config,
  lib,
  pkgs,
  ...
}:

{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "[$(date '+%H:%M:%S')] [INFO] ============================================"
    echo "[$(date '+%H:%M:%S')] [INFO] LaunchDaemon Bootstrap Check"
    echo "[$(date '+%H:%M:%S')] [INFO] ============================================"

    bootstrap_count=0
    already_loaded=0

    for plist in /Library/LaunchDaemons/org.nixos.*.plist /Library/LaunchDaemons/com.nix-darwin.*.plist; do
      if [ -f "$plist" ]; then
        # Extract label from plist, fallback to filename
        label=$(/usr/bin/plutil -extract Label raw "$plist" 2>/dev/null || basename "$plist" .plist)

        # Check if service is already loaded into launchd
        if ! /bin/launchctl print system/"$label" >/dev/null 2>&1; then
          echo "[$(date '+%H:%M:%S')] [INFO] Bootstrapping $label..."
          if /bin/launchctl bootstrap system "$plist" 2>/dev/null; then
            bootstrap_count=$((bootstrap_count + 1))
            echo "[$(date '+%H:%M:%S')] [INFO] ✓ Successfully bootstrapped $label"
          else
            echo "[$(date '+%H:%M:%S')] [WARN] Failed to bootstrap $label (may already be partially loaded)" >&2
          fi
        else
          already_loaded=$((already_loaded + 1))
          echo "[$(date '+%H:%M:%S')] [DEBUG] $label already loaded"
        fi
      fi
    done

    if [ $bootstrap_count -gt 0 ]; then
      echo "[$(date '+%H:%M:%S')] [INFO] Bootstrapped $bootstrap_count service(s)"
    fi
    if [ $already_loaded -gt 0 ]; then
      echo "[$(date '+%H:%M:%S')] [INFO] $already_loaded service(s) already loaded"
    fi

    echo "[$(date '+%H:%M:%S')] [INFO] LaunchDaemon bootstrap complete"
    echo "[$(date '+%H:%M:%S')] [INFO] ============================================"
  '';
}
