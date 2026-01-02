# Energy & Sleep Configuration
#
# macOS energy/sleep settings via pmset (Power Management Settings)
# Reference: https://ss64.com/mac/pmset.html
#
# Power sources:
#   -a  All power sources (battery, AC, UPS)
#   -c  AC power (plugged in)
#   -b  Battery
#   -u  UPS
#
# pmset parameters:
#   displaysleep N   - Display sleep timer (minutes, 0 = never)
#   sleep N          - System sleep timer (minutes, 0 = never)
#   disksleep N      - Disk spindown timer (minutes, 0 = never)
#   womp 0/1         - Wake on Magic Packet (Ethernet)
#   autorestart 0/1  - Restart after power failure
#   lidwake 0/1      - Wake on lid open (laptops)
#   acwake 0/1       - Wake on AC power connect

{ lib, config, ... }:

let
  cfg = config.system.energy;
in
{
  options.system.energy = {
    enable = lib.mkEnableOption "Energy and sleep configuration";

    # Display sleep (applies to all power sources)
    displaysleep = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Display sleep timer in minutes (0 = never). Applies to all power sources.";
    };

    # System sleep - separate for AC and battery
    sleep = {
      ac = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "System sleep timer when on AC power (0 = never)";
      };

      battery = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "System sleep timer when on battery (0 = never)";
      };
    };

    # Disk sleep (applies to all power sources)
    disksleep = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Disk spindown timer in minutes (0 = never). Set to 0 for SSDs.";
    };

    # Wake and restart options
    wakeOnMagicPacket = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Wake on Magic Packet (Wake-on-LAN)";
    };

    autoRestartOnPowerLoss = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically restart after power failure";
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.postActivation.text = lib.mkAfter ''
      # Configure macOS energy and sleep settings
      #
      # NOTE: Follows CRITICAL RULES from docs/ACTIVATION-SCRIPTS-RULES.md:
      #   * NEVER use 'set -e' - errors must not abort activation
      #   * All errors logged as warnings, not fatal
      #   * Must reach /run/current-system symlink update

      echo "Configuring energy and sleep settings..." >&2
      failures=0

      # Settings that apply to all power sources
      if sudo pmset -a \
        displaysleep ${toString cfg.displaysleep} \
        disksleep ${toString cfg.disksleep} \
        womp ${if cfg.wakeOnMagicPacket then "1" else "0"} \
        autorestart ${if cfg.autoRestartOnPowerLoss then "1" else "0"}; then
        echo "Common energy settings applied" >&2
      else
        echo "Warning: Failed to apply common energy settings (attempted: display ${toString cfg.displaysleep}m, disk ${toString cfg.disksleep}m)" >&2
        failures=$((failures + 1))
      fi

      # AC power (plugged in) settings
      if sudo pmset -c sleep ${toString cfg.sleep.ac}; then
        echo "AC power settings applied (sleep: ${toString cfg.sleep.ac} min)" >&2
      else
        echo "Warning: Failed to apply AC power settings (attempted: ${toString cfg.sleep.ac} min)" >&2
        failures=$((failures + 1))
      fi

      # Battery settings
      if sudo pmset -b sleep ${toString cfg.sleep.battery}; then
        echo "Battery settings applied (sleep: ${toString cfg.sleep.battery} min)" >&2
      else
        echo "Warning: Failed to apply battery settings (attempted: ${toString cfg.sleep.battery} min)" >&2
        failures=$((failures + 1))
      fi

      # Display current settings only if at least one phase succeeded
      if [ $failures -lt 3 ]; then
        echo "Current pmset configuration:" >&2
        sudo pmset -g || echo "Warning: Could not display pmset settings" >&2
      fi
    '';
  };
}
