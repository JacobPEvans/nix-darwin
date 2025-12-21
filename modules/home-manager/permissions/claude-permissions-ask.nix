# Claude Code Ask-Mode Commands (ASK List)
#
# Commands that require user confirmation before execution.
# Currently empty - all commands are either allowed or denied.
#
# SINGLE SOURCE OF TRUTH:
# Command definitions would go in ai-cli/common/permissions.nix
# This file only applies Claude-specific formatting.

{
  config,
  lib,
  ...
}:

{
  # Export ask permissions list (currently empty)
  ask = [ ];
}
