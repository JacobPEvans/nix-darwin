# Raycast Configuration Module
#
# Declarative Raycast preferences managed via macOS defaults.
# These settings persist across reinstalls and database resets.
#
# Usage:
#   programs.raycast.enable = true;
#
# Note: Only preference-type settings belong here.
# Dynamic data (quicklinks, snippets, history) lives in Raycast's
# encrypted SQLite databases and should be managed via Raycast's
# export/import feature.
#
# To see all available keys: defaults read com.raycast.macos
# Reference: https://raycast.com

{ lib, config, ... }:

let cfg = config.programs.raycast;
in {
  options.programs.raycast = {
    enable = lib.mkEnableOption "declarative Raycast preferences";
  };

  config = lib.mkIf cfg.enable {
    system.defaults.CustomUserPreferences = {
      "com.raycast.macos" = {
        # ========================================================================
        # Appearance
        # ========================================================================

        # Follow system dark/light mode
        # Default: true
        raycastShouldFollowSystemAppearance = true;

        # Window mode: "default" or "compact"
        # Default: "default"
        raycastPreferredWindowMode = "default";

        # ========================================================================
        # Menu Bar
        # ========================================================================

        # Show hyper key icon in menu bar
        # Default: false
        useHyperKeyIcon = false;

        # ========================================================================
        # Window Behavior
        # ========================================================================

        # Keep window open when clicking away
        # Default: false
        keepWindowVisibleOnResignKey = false;

        # ========================================================================
        # Quicklinks
        # ========================================================================

        # Auto-fill links in quicklinks
        # Default: true
        quicklinks_enableAutoFillLink = true;

        # Enable quick search for quicklinks
        # Default: true
        quicklinks_enableQuickSearch = true;

        # ========================================================================
        # Screenshots
        # ========================================================================

        # Copy screenshot to clipboard
        # Default: true
        mainWindowCaptureCopyToClipboard = true;

        # Open Finder after screenshot
        # Default: false
        mainWindowCaptureShowInFinder = false;

        # Show overlay after screenshot
        # Default: false
        mainWindowCaptureOpenQuickAccessOverlay = false;
      };
    };
  };
}
