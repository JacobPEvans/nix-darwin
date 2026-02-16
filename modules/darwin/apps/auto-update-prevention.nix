# Auto-Update Prevention for Nix-Managed Apps
#
# Disables built-in auto-updaters (Squirrel/ShipIt, Sparkle) for macOS apps
# managed via Nix to prevent version conflicts.
#
# Problem:
#   Apps like Postman use Squirrel/ShipIt to silently update themselves.
#   On next darwin-rebuild, Nix restores the older version via copyApps,
#   but the app's data was already migrated to the newer schema.
#   Result: "Version mismatch detected" errors and broken apps.
#
# Solution:
#   Use macOS defaults to disable auto-updaters declaratively.
#   This prevents the updater from running at all.
#
# Affected apps:
#   - postman (com.postmanlabs.mac) - Squirrel/ShipIt updater
#   - rapidapi (com.luckymarmot.Paw) - Sparkle updater
#
# Note: VS Code already handled via programs.vscode settings (no action needed).
#
# To verify settings are applied:
#   defaults read com.postmanlabs.mac SUEnableAutomaticChecks
#   defaults read com.luckymarmot.Paw SUEnableAutomaticChecks

_:

{
  system.defaults.CustomUserPreferences = {
    # Postman - Disable Squirrel/ShipIt auto-updater
    "com.postmanlabs.mac" = {
      SUEnableAutomaticChecks = false;
      SUAutomaticallyUpdate = false;
    };

    # RapidAPI (formerly Paw) - Disable Sparkle auto-updater
    "com.luckymarmot.Paw" = {
      SUEnableAutomaticChecks = false;
      SUAutomaticallyUpdate = false;
      SUAllowsAutomaticUpdates = false; # Sparkle-specific
    };
  };
}
