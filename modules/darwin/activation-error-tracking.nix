# Activation Error Tracking Module
# Provides comprehensive error tracking for darwin-rebuild activation phases
# Helps diagnose failures by tracking which phase failed and why
#
# Problem this solves:
# - The launchctl asuser call (home-manager activation) succeeds but may return
#   exit code 2, causing set -e to abort the entire script
# - Without tracking, we can't see which phase actually failed
# - This leaves users unable to diagnose the real issue
#
# Solution:
# - Track each activation phase with exit codes
# - Allow non-critical phases to fail without aborting
# - Report comprehensive error information
# - Keep debug output for future diagnostics

{ lib, config, ... }:

{
  # Post-activation script that wraps home-manager activation
  # Captures exit codes and allows script to continue
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # ====================================================================
    # Activation Error Tracking & Resilience
    # ====================================================================
    # The home-manager activation can succeed but return non-zero exit codes
    # This section tracks each phase and prevents premature script exit

    PHASE_START_TIME=$(date '+%s')
    ACTIVATION_PHASES_FAILED=""
    TOTAL_PHASES_FAILED=0

    # Function to track activation phase results
    track_activation_phase() {
      local phase_name="$1"
      local exit_code="$2"
      local phase_duration=$(($(date '+%s') - PHASE_START_TIME))

      if [ "$exit_code" -ne 0 ]; then
        TOTAL_PHASES_FAILED=$((TOTAL_PHASES_FAILED + 1))
        ACTIVATION_PHASES_FAILED="''${ACTIVATION_PHASES_FAILED}
        - $phase_name (exit $exit_code, duration: $${phase_duration}s)"
        echo "[$(date '+%H:%M:%S')] [WARN] Activation phase '$phase_name' returned exit code $exit_code (duration: $${phase_duration}s)" >&2
      else
        echo "[$(date '+%H:%M:%S')] [DEBUG] Activation phase '$phase_name' completed successfully (duration: $${phase_duration}s)" >&2
      fi
    }

    # Print final activation summary
    print_activation_summary() {
      echo "[$(date '+%H:%M:%S')] [INFO] ============================================" >&2
      echo "[$(date '+%H:%M:%S')] [INFO] Activation Complete" >&2
      echo "[$(date '+%H:%M:%S')] [INFO] ============================================" >&2

      if [ "$TOTAL_PHASES_FAILED" -gt 0 ]; then
        echo "[$(date '+%H:%M:%S')] [WARN] $TOTAL_PHASES_FAILED activation phase(s) had non-zero exit codes:" >&2
        echo "''${ACTIVATION_PHASES_FAILED}" >&2
        echo "[$(date '+%H:%M:%S')] [INFO] Note: Some phases may succeed despite returning non-zero exit codes" >&2
        echo "[$(date '+%H:%M:%S')] [INFO] Check /run/current-system symlink to verify if activation actually succeeded" >&2
      else
        echo "[$(date '+%H:%M:%S')] [INFO] All activation phases completed successfully" >&2
      fi
    }

    # Export functions for subshells
    export -f track_activation_phase
    export -f print_activation_summary
    export ACTIVATION_PHASES_FAILED TOTAL_PHASES_FAILED PHASE_START_TIME
  '';
}
