# Claude Code Permanently Blocked Commands (DENY List)
#
# This file defines commands that are PERMANENTLY blocked and cannot be approved.
# These represent catastrophic operations that should never be auto-executed.
#
# FILE STRUCTURE:
# - claude-permissions-allow.nix - Auto-approved commands
# - claude-permissions-ask.nix - Commands requiring user confirmation
# - claude-permissions-deny.nix (this file) - Permanently blocked commands
#
# NOTE: These permission lists are kept in sync across Claude, Gemini, and Copilot.
# Currently each AI has separate files. Future improvement: DRY refactor to share
# common command lists across all AI tools.
#
# SECURITY PHILOSOPHY:
# - These are truly catastrophic operations (system destruction, data exfiltration)
# - No user confirmation can override these blocks
# - If a legitimate use case arises, edit this file and rebuild

{ ... }:

let
  # === CATASTROPHIC FILE DESTRUCTION ===
  # Covers all rm -rf variants with /
  catastrophicFileDestruction = [
    "Bash(rm -rf /*:*)"           # rm -rf /
    "Bash(rm -rf /:*)"            # Alternative spacing
    "Bash(rm -rf ~:*)"            # Home directory destruction
    "Bash(rm -fr /*:*)"           # Reversed flags
    "Bash(rm -fr /:*)"
    "Bash(rm --recursive --force /*:*)"
    "Bash(rm --recursive --force /:*)"
  ];

  # === SENSITIVE FILE ACCESS ===
  # Credential files that should never be read by AI
  sensitiveFileAccess = [
    # Environment files (often contain secrets)
    "Read(.env)"
    "Read(.env.*)"
    "Read(**/.env)"
    "Read(**/.env.*)"
    "Read(**/secrets/**)"
    "Read(**/credentials/**)"

    # SSH/GPG/AWS credentials
    "Read(**/*_rsa)"
    "Read(**/*_dsa)"
    "Read(**/*_ecdsa)"
    "Read(**/*_ed25519)"
    "Read(~/.ssh/id_*)"
    "Read(~/.aws/credentials)"
    "Read(~/.gnupg/**)"
  ];

  # === HTTP WRITE OPERATIONS (Data Exfiltration) ===
  # Block all POST/PUT/DELETE/PATCH to prevent data theft
  httpWriteOperations = [
    "Bash(curl -X POST:*)"
    "Bash(curl -X PUT:*)"
    "Bash(curl -X DELETE:*)"
    "Bash(curl -X PATCH:*)"
    "Bash(curl --request POST:*)"
    "Bash(curl --request PUT:*)"
    "Bash(curl --request DELETE:*)"
    "Bash(curl --request PATCH:*)"
    "Bash(curl -d:*)"
    "Bash(curl --data:*)"
  ];

  # === SYSTEM-LEVEL DESTRUCTION ===
  systemDestruction = [
    "Bash(sudo rm:*)"
    "Bash(sudo dd:*)"
    "Bash(mkfs:*)"
    "Bash(fdisk:*)"
    "Bash(diskutil:*)"
  ];

  # === PRIVILEGE ESCALATION ===
  privilegeEscalation = [
    "Bash(sudo su:*)"
    "Bash(sudo -i:*)"
    "Bash(sudo bash:*)"
    "Bash(sudo -s:*)"
  ];

  # === REVERSE SHELLS / NETWORK LISTENERS ===
  reverseShells = [
    "Bash(nc -l:*)"
    "Bash(ncat -l:*)"
    "Bash(socat:*)"
  ];

in
{
  # Export the deny list (permanently blocked commands)
  denyList = catastrophicFileDestruction
    ++ sensitiveFileAccess
    ++ httpWriteOperations
    ++ systemDestruction
    ++ privilegeEscalation
    ++ reverseShells;
}
