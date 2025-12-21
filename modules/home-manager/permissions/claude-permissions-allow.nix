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
  # Error handling: Verify the ai-cli/common module exists and can be imported
  commonPath = ../ai-cli/common;
  aiCommon =
    if builtins.pathExists commonPath then
      import commonPath { inherit lib config; }
    else
      builtins.throw ''
        MIGRATION ERROR: ai-cli/common module not found at ${toString commonPath}

        This wrapper module expects the unified permission system to exist.
        If you're seeing this during migration, ensure:
        1. modules/home-manager/ai-cli/common/default.nix exists
        2. modules/home-manager/ai-cli/common/permissions.nix exists
        3. modules/home-manager/ai-cli/common/formatters.nix exists

        If you have stale builds, try: nix-collect-garbage && darwin-rebuild switch --flake .
      '';

  inherit (aiCommon) permissions formatters;

in
{
  # Export allowed permissions list
  # Combines shell commands (Bash(cmd:*)) with tool-specific permissions
  allow = formatters.claude.formatAllowed permissions;
}
