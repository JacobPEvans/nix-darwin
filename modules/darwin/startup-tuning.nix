# Startup Tuning — Disable Unnecessary Apple LaunchAgents
#
# macOS ships with many LaunchAgents enabled by default that aren't needed
# on every machine. Running unneeded daemons wastes resources and can cause
# boot-time race conditions where daemons start before their dependencies
# are ready, leading to crash-restart loops and degraded system performance.
#
# This module disables Apple LaunchAgents that are not required for this
# machine's configuration. Each entry documents what the daemon does,
# why it's not needed, and how to re-enable it.
#
# Disabled daemons:
#   - com.apple.universalaccessd: Accessibility services (VoiceOver, Zoom,
#     Hover Text). Not needed when no accessibility features are enabled.
#     Known to crash-loop at boot on macOS 26.3.x due to startup race
#     conditions, causing sustained UI performance degradation.
#   - com.apple.macos.studentd: Apple Classroom student daemon for
#     managed K-12 devices. Requires MDM enrollment entitlements that
#     personal devices don't have. Fails silently on every launch.
#   - com.apple.passd: Apple Wallet/Passes daemon. Not needed if Apple
#     Wallet is not actively used on this machine.
#
# Implementation:
#   `launchctl disable` persists to /var/db/com.apple.xpc.launchd/disabled.501.plist
#   and survives reboots. The activation script ensures the disabled state
#   is maintained across darwin-rebuild switch operations.
#
# Re-enabling:
#   Remove the service label from the list below and run:
#     launchctl enable gui/501/<service-label>
#   Then reboot to allow the daemon to start.

{ lib, ... }:

let
  uid = "501";

  # Apple LaunchAgents to disable — each entry documents why
  disabledAgents = [
    {
      label = "com.apple.universalaccessd";
      reason = "No accessibility features enabled; causes boot-time performance issues on macOS 26.3.x";
    }
    {
      label = "com.apple.macos.studentd";
      reason = "Apple Classroom daemon; requires MDM entitlements this device lacks";
    }
    {
      label = "com.apple.passd";
      reason = "Apple Wallet not used on this machine";
    }
  ];
in
{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # ====================================================================
    # Startup Tuning: Disable unnecessary Apple LaunchAgents
    # ====================================================================
    # See modules/darwin/startup-tuning.nix for documentation.
    _st_disabled=0
    ${lib.concatMapStringsSep "\n" (agent: ''
      if ! launchctl print-disabled "gui/${uid}" 2>/dev/null | grep -q '"${agent.label}" => disabled'; then
        launchctl disable "gui/${uid}/${agent.label}" 2>/dev/null || true
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Disabled ${agent.label} (${agent.reason})"
        _st_disabled=$((_st_disabled + 1))
      fi
    '') disabledAgents}
    if [ "$_st_disabled" -gt 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Startup tuning: disabled $_st_disabled unnecessary agent(s). Reboot required for effect."
    fi
  '';
}
