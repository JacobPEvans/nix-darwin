# Third-Party GUI Application Defaults
#
# macOS preferences for third-party GUI applications.
# Uses system.defaults.CustomUserPreferences to set defaults.
#
# Add new app configuration files here and import them below.

{ ... }:

{
  imports = [ ./orbstack.nix ./raycast.nix ];

  # OrbStack module is imported but host-specific config (apfsContainer)
  # must be set in hosts/<host>/default.nix
  # Data symlink configured in hosts/<host>/home.nix
}
