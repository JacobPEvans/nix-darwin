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

_:

let
  userConfig = import ../../../lib/user-config.nix;
  inherit (userConfig.user) homeDir;
in
{
  system.defaults.dock = {
    # ========================================================================
    # Left side of Dock (before separator) - Main apps
    # ========================================================================
    persistent-apps = [
      # Time & Tasks
      "/System/Applications/Clock.app"
      "/System/Applications/Reminders.app"
      "/System/Applications/Calendar.app"
      "/Applications/Toggl Track.app"

      # Communication
      "/System/Applications/Messages.app"
      "/Applications/Slack.app"
      "/Applications/Nix Apps/zoom.us.app"
      "/Applications/Webex.app"

      # Knowledge & Notes
      "/Applications/Nix Apps/Obsidian.app"
      # Note: Additional note-taking apps may be installed locally

      # Development & Tools
      "/Applications/Nix Apps/RapidAPI.app"
      "/Applications/Nix Apps/Visual Studio Code.app"
      "/System/Applications/Utilities/Terminal.app"
      "/Applications/Nix Apps/Bitwarden.app"
      "/Applications/OrbStack.app"

      # Browsers
      "/Applications/Safari.app"
      "/Applications/Brave Browser.app"

      # AI Tools
      "${homeDir}/Applications/Gemini.app"
      "/Applications/Ollama.app"
    ];

    # ========================================================================
    # Right side of Dock (after separator) - Folders & utilities
    # ========================================================================
    # Explicitly empty - prefer show-recents for temporary apps rather than
    # persisting folders/apps not managed by Nix. Add apps to persistent-apps
    # above when they should be permanent.
    persistent-others = [ ];
  };
}
