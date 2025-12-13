# GitHub Copilot CLI Recommended Deny Tools (DENY List)
#
# This file defines recommended --deny-tool flags for GitHub Copilot CLI.
# These are truly catastrophic operations that should always be blocked.
#
# FILE STRUCTURE:
# - copilot-permissions-allow.nix - Trusted directories (config.json)
# - copilot-permissions-ask.nix - Commands that would require confirmation (reference only)
# - copilot-permissions-deny.nix (this file) - Recommended --deny-tool flags
#
# NOTE: These permission lists are kept in sync across Claude, Gemini, and Copilot.
# Currently each AI has separate files. Future improvement: DRY refactor to share
# common command lists across all AI tools.
#
# IMPORTANT: Unlike Claude/Gemini, Copilot CLI requires runtime flags for tool
# permissions. This file is for REFERENCE - you must pass these as CLI flags:
#
#   copilot --deny-tool 'shell(rm -rf /)' --deny-tool 'shell(sudo rm)'
#
# Or create a shell alias/wrapper script.
#
# Only truly catastrophic operations are listed here. Common commands that might
# need user approval (like git reset, chmod, rm) are in the ask file for reference.

{ ... }:

let
  # === CATASTROPHIC FILE DESTRUCTION ===
  catastrophicFileDestruction = [
    "shell(rm -rf /)"
    "shell(rm -rf /*)"
    "shell(rm -rf ~)"
  ];

  # === HTTP WRITE OPERATIONS (Data Exfiltration) ===
  httpWriteOperations = [
    "shell(curl -X POST)"
    "shell(curl -X PUT)"
    "shell(curl -X DELETE)"
    "shell(curl -X PATCH)"
    "shell(curl --request POST)"
    "shell(curl --request PUT)"
    "shell(curl --request DELETE)"
    "shell(curl --request PATCH)"
    "shell(curl -d)"
    "shell(curl --data)"
  ];

  # === SYSTEM-LEVEL DESTRUCTION ===
  systemDestruction = [
    "shell(sudo rm)"
    "shell(sudo dd)"
    "shell(mkfs)"
    "shell(fdisk)"
    "shell(diskutil)"
  ];

  # === PRIVILEGE ESCALATION ===
  privilegeEscalation = [
    "shell(sudo su)"
    "shell(sudo -i)"
    "shell(sudo bash)"
    "shell(sudo -s)"
  ];

  # === REVERSE SHELLS / NETWORK LISTENERS ===
  reverseShells = [
    "shell(nc -l)"
    "shell(ncat -l)"
    "shell(socat)"
  ];

in
{
  # Export recommended deny tools (for use with --deny-tool flags)
  recommendedDenyTools =
    catastrophicFileDestruction
    ++ httpWriteOperations
    ++ systemDestruction
    ++ privilegeEscalation
    ++ reverseShells;

  # === USAGE EXAMPLE ===
  # Build a deny-tool command string:
  #
  # copilot \
  #   --deny-tool 'shell(rm -rf /)' \
  #   --deny-tool 'shell(sudo rm)' \
  #   --deny-tool 'shell(curl -X POST)'
  #
  # Or create a shell alias in your .zshrc:
  #   alias copilot-safe='copilot --deny-tool "shell(rm -rf /)" --deny-tool "shell(sudo rm)"'
}
