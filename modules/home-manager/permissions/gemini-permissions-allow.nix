# Gemini CLI Auto-Approved Commands (ALLOW List / coreTools)
#
# Uses unified permission definitions from ai-cli/common/permissions.nix
# with Gemini-specific formatting via formatters.nix.
#
# FORMAT: ShellTool(cmd) for shell commands, plus core tools like ReadFileTool
#
# SINGLE SOURCE OF TRUTH:
# Command definitions are in ai-cli/common/permissions.nix
# This file only applies Gemini-specific formatting.

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
  # Export coreTools list (allowed commands)
  # Combines Gemini-specific tools with formatted shell commands
  coreTools = formatters.gemini.formatCoreTools permissions;
}
