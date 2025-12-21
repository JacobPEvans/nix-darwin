# OpenCode Auto-Approved Commands (ALLOW List)
#
# Uses unified permission definitions from ai-cli/common/permissions.nix
# with OpenCode-specific formatting via formatters.nix.
#
# SINGLE SOURCE OF TRUTH:
# Command definitions are in ai-cli/common/permissions.nix
# This file only applies OpenCode-specific formatting.

{
  config,
  lib,
  ...
}:

let
  # Import unified permissions and formatters
  aiCommon = import ../ai-cli/common { inherit lib config; };
  inherit (aiCommon) permissions formatters;

in
{
  # Export allowedCommands list (auto-approved commands)
  # OpenCode config format TBD - currently passes through raw commands
  allowedCommands = formatters.opencode.formatShellCommands (
    lib.flatten (
      lib.mapAttrsToList (
        _name: value:
        if builtins.isList value then
          value
        else if builtins.isAttrs value then
          lib.flatten (lib.attrValues value)
        else
          [ ]
      ) permissions.allow
    )
  );
}
