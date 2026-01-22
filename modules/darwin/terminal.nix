# Terminal.app window size configuration using PlistBuddy
# for nested plist modification (defaults write cannot handle nested values).

{ lib, config, ... }:

let
  cfg = config.programs.terminal;
  userConfig = import ../../lib/user-config.nix;
in
{
  options.programs.terminal = {
    enable = lib.mkEnableOption "Terminal.app configuration";

    profile = lib.mkOption {
      type = lib.types.str;
      default = "Basic";
      description = "Terminal.app profile to configure.";
    };

    windowSize = {
      columns = lib.mkOption {
        type = lib.types.int;
        default = 180;
        description = "Number of columns for the Terminal window.";
      };

      rows = lib.mkOption {
        type = lib.types.int;
        default = 80;
        description = "Number of rows for the Terminal window.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.postActivation.text = lib.mkAfter ''
      echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Configuring Terminal.app window size..."
      failures=0

      PLIST="${userConfig.user.homeDir}/Library/Preferences/com.apple.Terminal.plist"
      PROFILE="${cfg.profile}"
      COLUMNS=${toString cfg.windowSize.columns}
      ROWS=${toString cfg.windowSize.rows}

      if [ ! -f "$PLIST" ]; then
        if plutil -create xml1 "$PLIST" 2>/dev/null; then
          echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Created Terminal.app plist"
        else
          echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] Failed to create Terminal.app plist" >&2
          failures=$((failures + 1))
        fi
      fi

      if ! /usr/libexec/PlistBuddy -c "Print 'Window Settings':$PROFILE" "$PLIST" >/dev/null 2>&1; then
        if ! /usr/libexec/PlistBuddy -c "Add 'Window Settings':$PROFILE dict" "$PLIST" 2>/dev/null; then
          echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] Failed to create profile dictionary" >&2
          failures=$((failures + 1))
        fi
      fi

      if /usr/libexec/PlistBuddy -c "Set 'Window Settings':$PROFILE:columnCount $COLUMNS" "$PLIST" 2>/dev/null ||
         /usr/libexec/PlistBuddy -c "Add 'Window Settings':$PROFILE:columnCount integer $COLUMNS" "$PLIST" 2>/dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Set columns to $COLUMNS"
      else
        echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] Failed to set columnCount" >&2
        failures=$((failures + 1))
      fi

      if /usr/libexec/PlistBuddy -c "Set 'Window Settings':$PROFILE:rowCount $ROWS" "$PLIST" 2>/dev/null ||
         /usr/libexec/PlistBuddy -c "Add 'Window Settings':$PROFILE:rowCount integer $ROWS" "$PLIST" 2>/dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Set rows to $ROWS"
      else
        echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] Failed to set rowCount" >&2
        failures=$((failures + 1))
      fi

      if [ $failures -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Terminal.app configured for ''${COLUMNS}x''${ROWS}"
      else
        echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] Terminal.app configuration completed with $failures failure(s)" >&2
      fi
    '';
  };
}
