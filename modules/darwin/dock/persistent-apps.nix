# Dock Persistent Apps
#
# Apps appear in the Dock in this exact order.
# Manual Dock changes WILL BE OVERWRITTEN on rebuild.
#
# App locations:
#   - System apps: /System/Applications/
#   - Nix system packages: /Applications/Nix Apps/
#   - Home Manager trampolines: ~/Applications/Home Manager Trampolines/
#   - Manual installs: /Applications/
#   - User apps: ~/Applications/
#
# NOTE: TCC-sensitive apps (Zoom, Ghostty) use Home Manager trampolines
# for persistent macOS permissions across darwin-rebuild.

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
      "${homeDir}/Applications/Home Manager Trampolines/zoom.us.app"
      "/Applications/Webex.app"

      # Knowledge & Notes
      "/Applications/Nix Apps/Obsidian.app"
      # Note: Additional note-taking apps may be installed locally

      # Development & Tools
      "/Applications/Nix Apps/RapidAPI.app"
      "/Applications/Nix Apps/Visual Studio Code.app"
      "${homeDir}/Applications/Home Manager Trampolines/Ghostty.app"
      "/Applications/Nix Apps/Bitwarden.app"
      "/Applications/Nix Apps/OrbStack.app"

      # Browsers
      "/Applications/Safari.app"
      "/Applications/Brave Browser.app"

      # AI Tools
      "${homeDir}/Applications/Gemini.app"
      # Ollama runs headless via LaunchAgent, no dock icon needed
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
