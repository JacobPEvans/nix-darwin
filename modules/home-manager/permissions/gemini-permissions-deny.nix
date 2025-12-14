# Gemini CLI Permanently Blocked Commands (DENY List / excludeTools)
#
# This file defines commands that are PERMANENTLY blocked via excludeTools.
# These represent catastrophic operations that should never be auto-executed.
#
# FILE STRUCTURE:
# - gemini-permissions-allow.nix - Auto-approved commands (coreTools)
# - gemini-permissions-ask.nix - Commands that would require confirmation (reference only)
# - gemini-permissions-deny.nix (this file) - Permanently blocked commands (excludeTools)
#
# NOTE: These permission lists are kept in sync across Claude, Gemini, and Copilot.
# These files are manually maintained - changes require darwin-rebuild to take effect.
# Currently each AI has separate files. Future improvement: DRY refactor to share
# common command lists across all AI tools.
#
# IMPORTANT: Only truly catastrophic operations belong here. Common commands that
# might need user approval (like git reset, chmod, rm, etc.) are in the ask file
# for reference, but Gemini CLI doesn't support an "ask" mode so they are NOT
# blocked here - the user must exercise caution with Gemini CLI.
#
# SECURITY PHILOSOPHY:
# - These are truly catastrophic operations (system destruction, data exfiltration)
# - No user confirmation can override these blocks
# - If a legitimate use case arises, edit this file and rebuild

_:

let
  # === CATASTROPHIC FILE DESTRUCTION ===
  catastrophicFileDestruction = [
    "ShellTool(rm -rf /)"
    "ShellTool(rm -rf /*)"
    "ShellTool(rm -rf ~)"
    "ShellTool(rm -fr /)"
    "ShellTool(rm -fr /*)"
    "ShellTool(rm --recursive --force /)"
    "ShellTool(rm --recursive --force /*)"
  ];

  # === HTTP WRITE OPERATIONS (Data Exfiltration) ===
  httpWriteOperations = [
    "ShellTool(curl -X POST)"
    "ShellTool(curl -X PUT)"
    "ShellTool(curl -X DELETE)"
    "ShellTool(curl -X PATCH)"
    "ShellTool(curl --request POST)"
    "ShellTool(curl --request PUT)"
    "ShellTool(curl --request DELETE)"
    "ShellTool(curl --request PATCH)"
    "ShellTool(curl -d)"
    "ShellTool(curl --data)"
  ];

  # === SYSTEM-LEVEL DESTRUCTION ===
  systemDestruction = [
    "ShellTool(sudo rm)"
    "ShellTool(sudo dd)"
    "ShellTool(mkfs)"
    "ShellTool(fdisk)"
    "ShellTool(diskutil)"
  ];

  # === PRIVILEGE ESCALATION ===
  privilegeEscalation = [
    "ShellTool(sudo su)"
    "ShellTool(sudo -i)"
    "ShellTool(sudo bash)"
    "ShellTool(sudo -s)"
  ];

  # === REVERSE SHELLS / NETWORK LISTENERS ===
  reverseShells = [
    "ShellTool(nc -l)"
    "ShellTool(ncat -l)"
    "ShellTool(socat)"
  ];

in
{
  # Export excludeTools (permanently blocked commands)
  excludeTools =
    catastrophicFileDestruction
    ++ httpWriteOperations
    ++ systemDestruction
    ++ privilegeEscalation
    ++ reverseShells;
}
