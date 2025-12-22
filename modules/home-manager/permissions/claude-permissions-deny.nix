# Claude Code Permanently Blocked Commands (DENY List)
#
# Uses unified permission definitions from ai-cli/common/permissions.nix
# with Claude-specific formatting via formatters.nix.
#
# FORMAT: Bash(cmd:*) for blocked shell commands, plus Read() patterns for sensitive files
#
# SINGLE SOURCE OF TRUTH:
# Command definitions are in ai-cli/common/permissions.nix
# This file only applies Claude-specific formatting.
#
# SECURITY PHILOSOPHY:
# - These are truly catastrophic operations (system destruction, data exfiltration)
# - Also blocks reading of sensitive files (.env, SSH keys, etc.)
# - No user confirmation can override these blocks
# - If a legitimate use case arises, edit ai-cli/common/permissions.nix

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
  # Export denied permissions list
  # Combines shell denies (Bash(cmd:*)) with sensitive file read blocks
  deny = formatters.claude.formatDenied permissions;
}
