# Claude Statusline Module
#
# Declarative statusline theme selection for Claude Code.
# Provides a unified interface for managing statusline themes and configuration.
#
# This module follows NixOS module patterns:
# - Options defined in options.nix
# - Theme implementations in separate files (powerline.nix, etc.)
# - Config logic uses lib.mkIf for conditional activation
#
# CURRENT STATUS:
# - powerline: WORKING (uses github:Owloops/claude-powerline)
# - robbyrussell: DEPRECATED (upstream repo 404)
# - advanced: DEPRECATED (upstream repo 404)
#
# Usage:
#   programs.claudeStatusline = {
#     enable = true;
#     theme = "powerline";
#     powerline.style = "dracula";  # default, minimal, rainbow, gruvbox, dracula, nord
#   };
{
  config,
  lib,
  ...
}:

let
  cfg = config.programs.claudeStatusline;
in
{
  imports = [
    ./options.nix
    ./robbyrussell.nix
    ./powerline.nix
    ./advanced.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      # Prevent conflicts between old and new statusline modules
      {
        assertion = !(config.programs.claude.statusLine.enhanced.enable or false);
        message = ''
          Both programs.claude.statusLine.enhanced and programs.claudeStatusline are enabled.

          This creates a conflict as both modules will try to deploy the statusline.
          Please use only one statusline module. The programs.claudeStatusline module
          is the new recommended interface.

          To fix:
          1. Set programs.claude.statusLine.enhanced.enable = false;
          2. Use programs.claudeStatusline with the powerline theme
        '';
      }
    ];
  };
}
