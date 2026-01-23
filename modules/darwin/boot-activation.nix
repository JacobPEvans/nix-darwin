# LaunchDaemon to create /run/current-system symlink at boot
# Separates critical symlink creation from full activation to avoid
# App Management permission issues during early boot.
#
# See: docs/boot-failure/root-cause.md
{
  config,
  lib,
  pkgs,
  ...
}:

let
  bootActivationScript = pkgs.writeShellScript "nix-boot-activation" ''
    #!/bin/bash
    LOG_FILE="/var/log/nix-boot-activation.log"

    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    }

    log "INFO: Starting minimal boot activation"

    TIMEOUT=60
    ELAPSED=0
    while [ ! -d /nix/store ] && [ $ELAPSED -lt $TIMEOUT ]; do
      sleep 1
      ELAPSED=$((ELAPSED + 1))
    done

    if [ $ELAPSED -ge $TIMEOUT ]; then
      log "ERROR: Timeout waiting for /nix/store after ''${TIMEOUT}s"
      exit 1
    fi

    if [ ! -d /nix/store ]; then
      log "ERROR: /nix/store not available after $ELAPSED seconds"
      exit 1
    fi

    log "INFO: /nix/store available after $ELAPSED seconds"

    SYSTEM_PROFILE="/nix/var/nix/profiles/system"
    if [ ! -L "$SYSTEM_PROFILE" ]; then
      log "ERROR: System profile $SYSTEM_PROFILE not found"
      exit 1
    fi

    SYSTEM_CONFIG_FILE="$SYSTEM_PROFILE/systemConfig"
    if [ ! -f "$SYSTEM_CONFIG_FILE" ]; then
      log "ERROR: System config file $SYSTEM_CONFIG_FILE not found"
      exit 1
    fi

    SYSTEM_CONFIG=$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$SYSTEM_CONFIG_FILE")
    log "INFO: System config: $SYSTEM_CONFIG"

    if [ -z "$SYSTEM_CONFIG" ]; then
      log "ERROR: System config path is empty after reading $SYSTEM_CONFIG_FILE"
      exit 1
    fi

    case "$SYSTEM_CONFIG" in
      /nix/store/*)
        ;;
      *)
        log "ERROR: System config path does not start with /nix/store/: $SYSTEM_CONFIG"
        exit 1
        ;;
    esac

    if [ ! -e "$SYSTEM_CONFIG" ]; then
      log "ERROR: System config target does not exist: $SYSTEM_CONFIG"
      exit 1
    fi

    if ln -sfn "$SYSTEM_CONFIG" /run/current-system 2>> "$LOG_FILE"; then
      log "INFO: Successfully created /run/current-system -> $SYSTEM_CONFIG"
    else
      log "ERROR: Failed to create /run/current-system symlink"
      exit 1
    fi

    if [ -d /nix/var/nix/gcroots ]; then
      ln -sfn /run/current-system /nix/var/nix/gcroots/current-system 2>> "$LOG_FILE"
      log "INFO: Updated GC root"
    fi

    if [ -L /run/current-system ]; then
      log "INFO: Verification passed - /run/current-system exists"
    else
      log "ERROR: Verification failed - /run/current-system not found after creation"
      exit 1
    fi

    log "INFO: Boot activation completed successfully"
    exit 0
  '';
in
{
  launchd.daemons.nix-boot-activation = {
    serviceConfig = {
      Label = "org.nixos.symlink-boot";

      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path /nix/store && exec /bin/bash ${bootActivationScript}"
      ];

      RunAtLoad = true;
      LaunchOnlyOnce = true;

      UserName = "root";
      GroupName = "wheel";

      StandardOutPath = "/var/log/nix-boot-activation.log";
      StandardErrorPath = "/var/log/nix-boot-activation.log";
    };
  };
}
