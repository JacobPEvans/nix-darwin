# Powerline Theme - Claude Code Statusline
#
# Multi-line statusline with powerline-style graphics.
# This is a placeholder for Issue #81.
#
# Features (planned):
# - Powerline-style arrow separators
# - Multi-line layout
# - Enhanced git status display
# - Customizable segments
{
  config,
  lib,
  ...
}:

let
  cfg = config.programs.claudeStatusline;
in
{
  config = lib.mkIf (cfg.enable && cfg.theme == "powerline") {
    # Placeholder implementation for Issue #81
    # When this theme is selected, provide a clear error message
    assertions = [
      {
        assertion = false;
        message = ''
          The 'powerline' statusline theme is not yet implemented.
          This theme is planned for Issue #81.

          Available themes:
          - robbyrussell (current default)

          To use the default theme, set:
            programs.claudeStatusline.theme = "robbyrussell";
        '';
      }
    ];
  };
}
