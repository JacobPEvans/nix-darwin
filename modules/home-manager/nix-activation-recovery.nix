# Login Activation Recovery
#
# Creates a LaunchAgent that runs after user login to recover from boot
# activation failures. This addresses the issue where nix-darwin's
# activate-system LaunchDaemon fails at boot due to App Management
# permission checks requiring a graphical session.
#
# The activation script requires "Aqua" (graphical session) for the
# App Management permission check. At boot time, there's no GUI yet,
# so activation fails with exit code 1. This LaunchAgent runs after
# login when the graphical session is available.
#
# See: docs/boot-failure/root-cause.md for full explanation
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.nix-activation-recovery;
  homeDir = config.home.homeDirectory;
  logFile = "${homeDir}/.local/log/nix-activation-recovery.log";

  # Script that checks for and recovers from activation failures
  activationRecoveryScript = pkgs.writeShellScript "nix-activation-recovery" ''
    #!/bin/bash
    set -euo pipefail

    LOG_FILE="${logFile}"
    mkdir -p "$(dirname "$LOG_FILE")"

    log() {
      local level="$1"
      local msg="$2"
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >> "$LOG_FILE"
    }

    # Check if activation is needed
    if [ -L /run/current-system ]; then
      log "INFO" "/run/current-system exists, no recovery needed"
      exit 0
    fi

    log "WARN" "/run/current-system missing - boot activation failed"
    log "INFO" "Attempting recovery activation..."

    # Run activation
    if sudo /nix/var/nix/profiles/system/activate >> "$LOG_FILE" 2>&1; then
      log "INFO" "Recovery activation completed successfully"

      # Verify the symlink was created
      if [ -L /run/current-system ]; then
        log "INFO" "/run/current-system now exists"

        # Send notification to user
        osascript -e 'display notification "Nix environment recovered successfully" with title "Nix Activation" subtitle "Boot recovery completed"' 2>/dev/null || true
      else
        log "ERROR" "/run/current-system still missing after activation"
        osascript -e 'display notification "Recovery may have failed - check logs" with title "Nix Activation" subtitle "Warning"' 2>/dev/null || true
      fi
    else
      local exit_code=$?
      log "ERROR" "Recovery activation failed with exit code $exit_code"
      osascript -e 'display notification "Activation recovery failed - manual intervention needed" with title "Nix Activation" subtitle "Error"' 2>/dev/null || true
    fi
  '';
in
{
  options.programs.nix-activation-recovery = {
    enable = lib.mkEnableOption "automatic nix-darwin activation recovery after login";
  };

  config = lib.mkIf cfg.enable {
    # Create a LaunchAgent that runs at login
    launchd.agents.nix-activation-recovery = {
      enable = true;
      config = {
        Label = "org.nixos.activation-recovery";
        ProgramArguments = [ "${activationRecoveryScript}" ];

        # Run once at login
        RunAtLoad = true;

        # Don't keep running
        KeepAlive = false;

        # Wait a bit for the system to settle after login
        # This ensures Aqua is fully available
        ThrottleInterval = 5;

        # Log output
        StandardOutPath = "/tmp/nix-activation-recovery-stdout.log";
        StandardErrorPath = "/tmp/nix-activation-recovery-stderr.log";
      };
    };
  };
}
