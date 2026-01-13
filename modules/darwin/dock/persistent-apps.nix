# Dock Persistent Apps
#
# Apps appear in the Dock in this exact order.
# Manual Dock changes WILL BE OVERWRITTEN on rebuild.
#
# App locations:
#   - System apps: /System/Applications/
#   - Nix system packages: /Applications/Nix Apps/
#   - Home Manager apps (copyApps): ~/Applications/Home Manager Apps/
#   - Manual installs: /Applications/
#   - User apps: ~/Applications/
#
# NOTE: TCC-sensitive apps (Ghostty, VS Code) use copyApps (migrated
# from mac-app-util trampolines) for stable paths that persist macOS TCC
# permissions across darwin-rebuild.

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
      "/Applications/Shortwave.app" # AI-powered email client (homebrew cask)
      "/Applications/Slack.app"
      # "${homeDir}/Applications/Home Manager Apps/zoom.us.app" # DISABLED - no longer using Zoom
      "/Applications/Webex.app"

      # AI Assistants
      "${homeDir}/Applications/Gemini.app" # Google Gemini AI assistant
      "/Applications/Claude.app" # Anthropic Claude desktop app (homebrew cask)

      # Knowledge & Notes
      "/Applications/Nix Apps/Obsidian.app"
      # Note: Additional note-taking apps may be installed locally

      # Development & Tools
      "${homeDir}/Applications/Home Manager Apps/RapidAPI.app"
      "${homeDir}/Applications/Home Manager Apps/Postman.app"
      "${homeDir}/Applications/Home Manager Apps/Visual Studio Code.app"
      "${homeDir}/Applications/Home Manager Apps/Ghostty.app"
      "/Applications/Nix Apps/Bitwarden.app"
      "/Applications/Nix Apps/OrbStack.app"

      # Browsers
      "/Applications/Safari.app"
      "/Applications/Brave Browser.app"

      # NOTE: Ollama runs headless via LaunchAgent, no dock icon needed.
      # NOTE: Additional AI tools (Antigravity, ChatGPT, Cursor) can be found in
      # ~/Applications/Home Manager Apps/ but are not pinned to the Dock.
    ];

    # ========================================================================
    # Right side of Dock (after separator) - Folders & utilities
    # ========================================================================
    # No persistent folders configured.
    # Recent apps will appear here if show-recents is enabled.
    persistent-others = [ ];
  };
}
