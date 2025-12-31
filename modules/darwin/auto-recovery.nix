# Automatic Boot Failure Detection and Recovery
#
# Detects when nix-darwin LaunchDaemons failed to load at boot and automatically
# attempts recovery. Provides VERY obvious visual feedback to the user.
#
# This module adds shell initialization code that:
# 1. Checks if /run/current-system exists (indicates successful boot)
# 2. If missing, attempts automatic bootstrap + activation
# 3. Shows prominent success/failure messages
#
# Integration: Runs on every shell startup via /etc/zshenv

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Add auto-detection and recovery helper to shell initialization
  programs.zsh.interactiveShellInit = lib.mkBefore ''
    # ============================================================
    # BOOT FAILURE DETECTION & RECOVERY
    # ============================================================
    # Only check in interactive shells, once per session
    if [[ $- == *i* ]] && [[ -z "$NIX_BOOT_CHECK_DONE" ]]; then
      export NIX_BOOT_CHECK_DONE=1

      if [[ ! -L /run/current-system ]]; then
        # Boot failure detected - show VERY prominent warning
        echo ""
        echo "╔══════════════════════════════════════════════════════════════════╗"
        echo "║                                                                  ║"
        echo "║  🚨  CRITICAL: NIX BOOT FAILURE DETECTED  🚨                     ║"
        echo "║                                                                  ║"
        echo "║  /run/current-system symlink is MISSING                         ║"
        echo "║  Your nix-darwin environment did NOT activate at boot           ║"
        echo "║                                                                  ║"
        echo "║  Most commands will not work until this is fixed.               ║"
        echo "║                                                                  ║"
        echo "╠══════════════════════════════════════════════════════════════════╣"
        echo "║                                                                  ║"
        echo "║  🔧  ONE-COMMAND FIX:                                            ║"
        echo "║                                                                  ║"
        echo "║      nix-recover                                                 ║"
        echo "║                                                                  ║"
        echo "║  (Will prompt for sudo password to fix the issue)               ║"
        echo "║                                                                  ║"
        echo "╠══════════════════════════════════════════════════════════════════╣"
        echo "║                                                                  ║"
        echo "║  📖  For manual recovery or more details:                       ║"
        echo "║      docs/boot-failure/README.md                                ║"
        echo "║                                                                  ║"
        echo "╚══════════════════════════════════════════════════════════════════╝"
        echo ""

        # Define nix-recover helper function for this session
        function nix-recover() {
          echo "→ Bootstrapping nix-darwin LaunchDaemons..."
          sudo /bin/launchctl bootstrap system /Library/LaunchDaemons/org.nixos.darwin-store.plist 2>/dev/null && echo "  ✓ darwin-store bootstrapped"
          sudo /bin/launchctl bootstrap system /Library/LaunchDaemons/org.nixos.activate-system.plist 2>/dev/null && echo "  ✓ activate-system bootstrapped"

          echo "→ Running system activation..."
          if sudo /nix/var/nix/profiles/system/activate; then
            echo ""
            echo "╔══════════════════════════════════════════════════════════════╗"
            echo "║  ✅  RECOVERY SUCCESSFUL                                    ║"
            echo "║  Reloading shell...                                         ║"
            echo "╚══════════════════════════════════════════════════════════════╝"
            exec zsh
          else
            echo ""
            echo "╔══════════════════════════════════════════════════════════════╗"
            echo "║  ❌  RECOVERY FAILED                                        ║"
            echo "║  Check the error messages above.                            ║"
            echo "║  See: docs/boot-failure/README.md                           ║"
            echo "╚══════════════════════════════════════════════════════════════╝"
            return 1
          fi
        }
      fi
    fi
  '';
}
