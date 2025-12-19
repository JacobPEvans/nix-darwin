# Claude Statusline Options
#
# Declarative statusline theme selection for Claude Code.
# Provides mkOption definitions for theme-based statusline configuration.
{ lib, ... }:

with lib;

{
  options.programs.claudeStatusline = {
    enable = mkEnableOption "Claude Code statusline with theme support";

    theme = mkOption {
      type = types.enum [
        "robbyrussell"
        "powerline"
        "advanced"
      ];
      default = "robbyrussell";
      description = ''
        Statusline theme to use.

        Available themes:
        - robbyrussell: Simple, clean single-line statusline (current default)
        - powerline: Multi-line statusline with powerline-style graphics (Issue #81)
        - advanced: Full-featured statusline with system info (Issue #82)
      '';
      example = "robbyrussell";
    };

    # Theme-specific configuration
    powerline = mkOption {
      type = types.submodule {
        options = {
          style = mkOption {
            type = types.enum [
              "default"
              "minimal"
              "rainbow"
              "gruvbox"
              "dracula"
              "nord"
            ];
            default = "default";
            description = ''
              Powerline style variant.

              Available styles:
              - default: Standard powerline look
              - minimal: Clean, simple
              - rainbow: Colorful segments
              - gruvbox: Gruvbox color scheme
              - dracula: Dracula theme
              - nord: Nord color palette
            '';
          };
        };
      };
      default = { };
      description = "Powerline theme-specific options";
    };

    advanced = mkOption {
      type = types.submodule {
        options = {
          theme = mkOption {
            type = types.str;
            default = "gruvbox";
            description = "Color theme for advanced statusline (for future use in Issue #82)";
          };

          showSystemInfo = mkOption {
            type = types.bool;
            default = true;
            description = "Show system information in advanced statusline (for future use in Issue #82)";
          };
        };
      };
      default = { };
      description = "Advanced theme-specific options (for future use in Issue #82)";
    };
  };
}
