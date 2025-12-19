# Advanced Theme - Claude Code Statusline
#
# Full-featured statusline with system information and theming.
# This is a placeholder for Issue #82.
#
# Features (planned):
# - System information display (CPU, memory, disk)
# - Customizable color themes
# - Extended git information
# - Performance metrics
# - Context-aware segments
{
  config,
  lib,
  ...
}:

let
  cfg = config.programs.claudeStatusline;
in
{
  config = lib.mkIf (cfg.enable && cfg.theme == "advanced") {
    # Placeholder implementation for Issue #82
    # When this theme is selected, provide a clear error message
    assertions = [
      {
        assertion = false;
        message = ''
          The 'advanced' statusline theme is not yet implemented.
          This theme is planned for Issue #82.

          Available themes:
          - robbyrussell (current default)

          To use the default theme, set:
            programs.claudeStatusline.theme = "robbyrussell";
        '';
      }
    ];
  };
}
