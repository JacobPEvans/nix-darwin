# Claude Code Auto-Approved Commands (ALLOW List)
#
# Uses unified permission definitions from ai-cli/common/permissions.nix
# with Claude-specific formatting via formatters.nix.
#
# FORMAT: Bash(cmd:*) for shell commands, plus tool-specific patterns
#
# SINGLE SOURCE OF TRUTH:
# Command definitions are in ai-cli/common/permissions.nix
# This file only applies Claude-specific formatting.

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
  # Export allowed permissions list
  # Combines shell commands (Bash(cmd:*)) with tool-specific permissions
  allow = formatters.claude.formatAllowed permissions;
}
