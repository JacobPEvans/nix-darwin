# Terminal.app Configuration Module
#
# macOS Terminal.app stores window settings in nested plist structures
# that require PlistBuddy for modification. Standard `defaults write`
# cannot set nested dictionary values.
#
# Usage:
#   programs.terminal = {
#     enable = true;
#     windowSize = {
#       columns = 180;
#       rows = 80;
#     };
#   };

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
      # Configure Terminal.app default profile window size
      #
      # NOTE: This activation script follows CRITICAL RULES from modules/darwin/common.nix:
      #   * NEVER use 'set -e' - errors must not abort the script
      #   * All errors logged as warnings, not fatal failures
      #   * Must reach /run/current-system symlink update (symlink update is critical)
      # This is why we use 'if ... then ... else echo warning' instead of '|| exit' patterns
      PLIST="${userConfig.user.homeDir}/Library/Preferences/com.apple.Terminal.plist"
      PROFILE="${cfg.profile}"
      COLUMNS=${toString cfg.windowSize.columns}
      ROWS=${toString cfg.windowSize.rows}

      # Ensure the plist file exists; create it if missing (e.g., fresh install)
      if [ ! -f "$PLIST" ]; then
        # Terminal.app hasn't been launched yet - create minimal plist
        plutil -create xml1 "$PLIST"
        echo "Created Terminal.app plist file" >&2
      fi

      # Ensure the profile dictionary exists
      if ! /usr/libexec/PlistBuddy -c "Print 'Window Settings':$PROFILE" "$PLIST" >/dev/null 2>&1; then
        if ! /usr/libexec/PlistBuddy -c "Add 'Window Settings':$PROFILE dict" "$PLIST" 2>/dev/null; then
          echo "Error: Could not create profile dictionary 'Window Settings':$PROFILE" >&2
        fi
      fi

      # Track success for final message
      colSuccess=0
      rowSuccess=0

      # Set columns for the profile
      if /usr/libexec/PlistBuddy -c "Set 'Window Settings':$PROFILE:columnCount $COLUMNS" "$PLIST" 2>/dev/null; then
        colSuccess=1
      elif /usr/libexec/PlistBuddy -c "Add 'Window Settings':$PROFILE:columnCount integer $COLUMNS" "$PLIST" 2>/dev/null; then
        colSuccess=1
      else
        echo "Error: Failed to set columnCount for Terminal profile '$PROFILE'" >&2
      fi

      # Set rows for the profile
      if /usr/libexec/PlistBuddy -c "Set 'Window Settings':$PROFILE:rowCount $ROWS" "$PLIST" 2>/dev/null; then
        rowSuccess=1
      elif /usr/libexec/PlistBuddy -c "Add 'Window Settings':$PROFILE:rowCount integer $ROWS" "$PLIST" 2>/dev/null; then
        rowSuccess=1
      else
        echo "Error: Failed to set rowCount for Terminal profile '$PROFILE'" >&2
      fi

      # Report success or failure
      if [ $colSuccess -eq 1 ] && [ $rowSuccess -eq 1 ]; then
        echo "Terminal.app profile '$PROFILE' configured for ''${COLUMNS}x''${ROWS}" >&2
      else
        echo "Warning: Terminal.app profile '$PROFILE' configuration incomplete" >&2
      fi
    '';
  };
}
