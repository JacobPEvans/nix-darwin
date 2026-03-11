# Boot failure detection via shell initialization
# Checks for /run/current-system and provides nix-recover helper function

{ lib, ... }:

{
  programs.zsh.interactiveShellInit = lib.mkBefore ''
    if [[ $- == *i* ]] && [[ -z "$NIX_BOOT_CHECK_DONE" ]]; then
      export NIX_BOOT_CHECK_DONE=1

      if [[ ! -L /run/current-system ]]; then
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

        nix-recover() {
          echo "→ Bootstrapping nix-darwin LaunchDaemons..."

          if [[ -f /Library/LaunchDaemons/org.nixos.darwin-store.plist ]]; then
            if sudo /bin/launchctl bootstrap system /Library/LaunchDaemons/org.nixos.darwin-store.plist 2>/dev/null; then
              echo "  ✓ darwin-store bootstrapped"
            else
              echo "  ⚠ darwin-store already loaded or bootstrap failed"
            fi
          else
            echo "  ⚠ darwin-store plist not found, skipping"
          fi

          if [[ -f /Library/LaunchDaemons/org.nixos.activate-system.plist ]]; then
            if sudo /bin/launchctl bootstrap system /Library/LaunchDaemons/org.nixos.activate-system.plist 2>/dev/null; then
              echo "  ✓ activate-system bootstrapped"
            else
              echo "  ⚠ activate-system already loaded or bootstrap failed"
            fi
          else
            echo "  ⚠ activate-system plist not found, skipping"
          fi

          if [[ -f /Library/LaunchDaemons/org.nixos.symlink-boot.plist ]]; then
            if sudo /bin/launchctl bootstrap system /Library/LaunchDaemons/org.nixos.symlink-boot.plist 2>/dev/null; then
              echo "  ✓ symlink-boot bootstrapped"
            else
              echo "  ⚠ symlink-boot already loaded or bootstrap failed"
            fi
          else
            echo "  ⚠ symlink-boot plist not found, skipping"
          fi

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
