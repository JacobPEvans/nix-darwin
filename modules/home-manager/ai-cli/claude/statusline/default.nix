# Claude Statusline Module
#
# Declarative statusline theme selection for Claude Code.
# Provides a unified interface for managing statusline themes and configuration.
#
# This module follows NixOS module patterns:
# - Options defined in options.nix
# - Theme implementations in separate files (robbyrussell.nix, powerline.nix, advanced.nix)
# - Config logic uses lib.mkIf for conditional activation
#
# Usage:
#   programs.claudeStatusline = {
#     enable = true;
#     theme = "robbyrussell";  # robbyrussell | powerline | advanced
#   };
#
# Related Issues:
# - #80: This module (options framework)
# - #81: Powerline theme implementation
# - #82: Advanced theme implementation
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
      # Check for enhanced.enable specifically, not the top-level enable, because:
      # - Users need to set enhanced.source for the robbyrussell theme
      # - Setting enhanced.source requires accessing the legacy option namespace
      # - The conflict only occurs when enhanced.enable is true (deploys statusline)
      {
        assertion = !(config.programs.claude.statusLine.enhanced.enable or false);
        message = ''
          Both programs.claude.statusLine.enhanced and programs.claudeStatusline are enabled.

          This creates a conflict as both modules will try to deploy the statusline.
          Please use only one statusline module. The programs.claudeStatusline module
          is the new recommended interface.

          To migrate:
          1. Set programs.claude.statusLine.enhanced.enable = false;
          2. Keep programs.claude.statusLine.enhanced.source configured (needed for now)
          3. Use programs.claudeStatusline with your chosen theme
        '';
      }

      # Validate source configuration for robbyrussell theme
      # Note: This assertion allows powerline/advanced themes without source configuration,
      # since those themes will have their own source requirements in future implementations.
      # Only robbyrussell currently requires the legacy source configuration.
      {
        assertion =
          cfg.theme != "robbyrussell" || (config.programs.claude.statusLine.enhanced.source or null) != null;
        message = ''
          programs.claudeStatusline is enabled with theme 'robbyrussell', but source is not configured.

          The robbyrussell theme requires the claude-code-statusline source to be specified.
          Please configure the source (without enabling the legacy enhanced module):

            programs.claude.statusLine.enhanced = {
              # enable = false;  # Keep disabled to avoid conflicts
              source = inputs.claude-code-statusline;
            };

          Then enable the new statusline module:
            programs.claudeStatusline = {
              enable = true;
              theme = "robbyrussell";
            };

          Note: This is a transitional requirement. Future versions will consolidate
          the source configuration into programs.claudeStatusline directly.
        '';
      }
    ];
  };
}
