# Claude Statusline Options
#
# Declarative statusline theme selection for Claude Code.
# Provides mkOption definitions for theme-based statusline configuration.
{ lib, ... }:

let
  # Import shared theme definitions
  themes = import ./themes.nix { };
  inherit (themes) availableThemes;
in
{
  options.programs.claudeStatusline = {
    enable = lib.mkEnableOption "Claude Code statusline with theme support";

    theme = lib.mkOption {
      type = lib.types.enum [
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
    powerline = lib.mkOption {
      type = lib.types.submodule {
        options = {
          style = lib.mkOption {
            type = lib.types.enum [
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

    advanced = lib.mkOption {
      type = lib.types.submodule {
        options = {
          theme = lib.mkOption {
            type = lib.types.enum availableThemes;
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

          showSystemInfo = lib.mkOption {
            type = lib.types.bool;
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
