# OpenCode Denied Commands (DENY List)
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
  # Export deniedCommands list (permanently blocked commands)
  # OpenCode config format TBD - currently passes through raw commands
  deniedCommands = formatters.opencode.formatShellCommands (
    formatters.utils.flattenCommands permissions.deny
  );
}
