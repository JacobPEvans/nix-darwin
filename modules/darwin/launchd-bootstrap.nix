# Bootstrap nix-darwin LaunchDaemons using modern launchctl API
#
# Workaround for https://github.com/nix-darwin/nix-darwin/issues/1255
# (deprecated launchctl load doesn't persist across reboots on modern macOS)
#
# See: docs/boot-failure/ for full documentation

{
  config,
  lib,
  pkgs,
  ...
}:

{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Checking LaunchDaemon bootstrap status..."
    failures=0
    bootstrap_count=0
    already_loaded=0

    for plist in /Library/LaunchDaemons/org.nixos.*.plist /Library/LaunchDaemons/com.nix-darwin.*.plist; do
      if [ -f "$plist" ]; then
        label=$(/usr/bin/plutil -extract Label raw "$plist" 2>/dev/null || basename "$plist" .plist)

        if ! /bin/launchctl print system/"$label" >/dev/null 2>&1; then
          if /bin/launchctl bootstrap system "$plist" 2>/dev/null; then
            bootstrap_count=$((bootstrap_count + 1))
            echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Bootstrapped $label"
          else
            echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] Failed to bootstrap $label" >&2
            failures=$((failures + 1))
          fi
        else
          already_loaded=$((already_loaded + 1))
        fi
      fi
    done

    if [ $failures -eq 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] LaunchDaemon bootstrap complete ($bootstrap_count new, $already_loaded already loaded)"
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] LaunchDaemon bootstrap completed with $failures failure(s)" >&2
    fi
  '';
}
