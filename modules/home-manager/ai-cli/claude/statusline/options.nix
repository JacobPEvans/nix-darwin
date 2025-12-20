# Claude Statusline Options
#
# Declarative statusline theme selection for Claude Code.
# Provides mkOption definitions for theme-based statusline configuration.
{ lib, ... }:

with lib;

let
  # Import shared theme definitions
  themes = import ./themes.nix { };
  inherit (themes) availableThemes;
in
{
  options.programs.claudeStatusline = {
    enable = mkEnableOption "Claude Code statusline with theme support";

    theme = mkOption {
      type = types.enum [
        "powerline"
        "robbyrussell"
        "advanced"
      ];
      default = "powerline";
      description = ''
        Statusline theme to use.

        Available themes:
        - powerline: Multi-line statusline with powerline-style graphics (RECOMMENDED)
          Uses github:Owloops/claude-powerline (actively maintained)
        - robbyrussell: DEPRECATED (upstream repo 404)
        - advanced: DEPRECATED (upstream repo 404)
      '';
      example = "powerline";
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
            type = types.enum availableThemes;
            default = "gruvbox";
            description = ''
              Color theme for advanced statusline.

              Available themes (18+):
              - gruvbox (default)
              - nord
              - dracula
              - monokai
              - solarized-dark, solarized-light
              - tokyo-night
              - catppuccin-mocha, catppuccin-latte, catppuccin-frappe, catppuccin-macchiato
              - onedark
              - github-dark, github-light
              - material
              - palenight
              - ayu-dark, ayu-light
            '';
            example = "nord";
          };

          showSystemInfo = mkOption {
            type = types.bool;
            default = true;
            description = "Show system information in advanced statusline (CPU, memory, disk)";
          };
        };
      };
      default = { };
      description = "Advanced theme-specific options (Issue #82)";
    };
  };
}
