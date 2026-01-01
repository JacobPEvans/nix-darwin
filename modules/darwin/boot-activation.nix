# Boot Activation - Minimal Symlink Creation
#
# Creates a LaunchDaemon that ONLY creates /run/current-system symlink at boot.
# This is a workaround for the issue where nix-darwin's activate-system fails
# due to App Management permission checks requiring a graphical session.
#
# By separating the critical symlink creation from the full activation,
# boot-time services (Ollama, OrbStack, etc.) can start even if the full
# activation fails.
#
# The full activation (with App Management) can run later at user login or
# on first darwin-rebuild.
#
# See: docs/boot-failure/root-cause.md for full explanation
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Script that creates ONLY the /run/current-system symlink
  # No permission checks, no App Management, just the critical symlink
  bootActivationScript = pkgs.writeShellScript "nix-boot-activation" ''
    #!/bin/bash

    LOG_FILE="/var/log/nix-boot-activation.log"

    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    }

    log "INFO: Starting minimal boot activation"

    # Wait for /nix/store with a reasonable timeout (60 seconds)
    TIMEOUT=60
    ELAPSED=0
    while [ ! -d /nix/store ] && [ $ELAPSED -lt $TIMEOUT ]; do
      sleep 1
      ELAPSED=$((ELAPSED + 1))
    done

    # Explicit timeout check - ensures we exit with error if timeout was reached
    if [ $ELAPSED -ge $TIMEOUT ]; then
      log "ERROR: Timeout waiting for /nix/store after ''${TIMEOUT}s"
      exit 1
    fi

    if [ ! -d /nix/store ]; then
      log "ERROR: /nix/store not available after $ELAPSED seconds"
      exit 1
    fi

    log "INFO: /nix/store available after $ELAPSED seconds"

    # Check for system profile
    SYSTEM_PROFILE="/nix/var/nix/profiles/system"
    if [ ! -L "$SYSTEM_PROFILE" ]; then
      log "ERROR: System profile $SYSTEM_PROFILE not found"
      exit 1
    fi

    # Read the system config
    SYSTEM_CONFIG_FILE="$SYSTEM_PROFILE/systemConfig"
    if [ ! -f "$SYSTEM_CONFIG_FILE" ]; then
      log "ERROR: System config file $SYSTEM_CONFIG_FILE not found"
      exit 1
    fi

    SYSTEM_CONFIG=$(cat "$SYSTEM_CONFIG_FILE" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    log "INFO: System config: $SYSTEM_CONFIG"

    # Validate system config path before creating symlink
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

    # Create the critical /run/current-system symlink
    if ln -sfn "$SYSTEM_CONFIG" /run/current-system 2>> "$LOG_FILE"; then
      log "INFO: Successfully created /run/current-system -> $SYSTEM_CONFIG"
    else
      log "ERROR: Failed to create /run/current-system symlink"
      exit 1
    fi

    # Also update the GC root
    if [ -d /nix/var/nix/gcroots ]; then
      ln -sfn /run/current-system /nix/var/nix/gcroots/current-system 2>> "$LOG_FILE"
      log "INFO: Updated GC root"
    fi

    # Verify the symlink
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
  # Create a LaunchDaemon that runs EARLY at boot
  # This runs BEFORE the full activate-system and just creates the symlink
  launchd.daemons.nix-boot-activation = {
    serviceConfig = {
      # More descriptive name - this service ONLY creates the symlink, not full activation
      Label = "org.nixos.symlink-boot";

      # CRITICAL: Use /bin/wait4path to wait for /nix/store BEFORE running script
      # This prevents the "No such file or directory" error when /nix/store
      # isn't mounted yet at early boot time.
      # Same pattern as org.nixos.activate-system.plist
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path /nix/store && exec /bin/bash ${bootActivationScript}"
      ];

      # Run at load (boot time)
      RunAtLoad = true;

      # Only run once per boot - no retry logic to prevent potential infinite loops
      # If this fails, the user will be prompted via auto-recovery.nix at shell init
      LaunchOnlyOnce = true;

      # Run as root
      UserName = "root";
      GroupName = "wheel";

      # Log output
      StandardOutPath = "/var/log/nix-boot-activation.log";
      StandardErrorPath = "/var/log/nix-boot-activation.log";

      # NOTE: Removed KeepAlive and StartInterval which created contradictory behavior
      # with LaunchOnlyOnce. The original configuration would retry infinitely every 30s
      # even on successful completion. If boot activation fails, auto-recovery.nix handles
      # user notification and manual recovery via nix-recover.
    };
  };
}
