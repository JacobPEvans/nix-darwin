# Dock Persistent Apps
#
# Apps appear in the Dock in this exact order.
# Manual Dock changes WILL BE OVERWRITTEN on rebuild.
#
# App locations:
#   - System apps: /System/Applications/
#   - Nix-managed: /Applications/Nix Apps/
#   - Manual installs: /Applications/
#   - User apps: ~/Applications/

{ ... }:

let
  userConfig = import ../../../lib/user-config.nix;
  homeDir = userConfig.user.homeDir;
in
{
  system.defaults.dock = {
    # ========================================================================
    # Left side of Dock (before separator) - Main apps
    # ========================================================================
    persistent-apps = [
      # Communication
      "/System/Applications/Calendar.app"
      "/Applications/Slack.app"
      "/Applications/Nix Apps/zoom.us.app"
      "/System/Applications/Messages.app"

      # Productivity
      "/System/Applications/Reminders.app"
      "/Applications/Toggl Track.app"
      "/System/Applications/Clock.app"
      "/Applications/Nix Apps/Obsidian.app"
      "/Applications/Granola.app"

      # Development & Tools
      "/Applications/Nix Apps/Visual Studio Code.app"
      "/System/Applications/Utilities/Terminal.app"
      "/Applications/Nix Apps/Bitwarden.app"
      "/Applications/OrbStack.app"

      # Browsers
      "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
      "/Applications/Brave Browser.app"
      "/Applications/Google Chrome.app"

      # AI Tools
      "${homeDir}/Applications/Gemini.app"
      "/Applications/Ollama.app"
    ];

    # ========================================================================
    # Right side of Dock (after separator) - Folders & utilities
    # ========================================================================
    persistent-others = [
      "${homeDir}/Applications/Mind Tickle.app"
      "/System/Applications/TextEdit.app"
      "/System/Applications/iPhone Mirroring.app"
      "/System/Applications/System Settings.app"
    ];
  };
}
