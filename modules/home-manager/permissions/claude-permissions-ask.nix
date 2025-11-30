# Claude Code User-Prompted Commands (ASK List)
#
# This file defines commands that require explicit user approval.
# These are potentially dangerous but may be necessary in specific contexts.
#
# FILE STRUCTURE:
# - claude-permissions-allow.nix - Auto-approved commands
# - claude-permissions-ask.nix (this file) - Commands requiring user confirmation
# - claude-permissions-deny.nix - Permanently blocked commands
#
# NOTE: These permission lists are kept in sync across Claude, Gemini, and Copilot.
# Currently each AI has separate files. Future improvement: DRY refactor to share
# common command lists across all AI tools.
#
# SECURITY STRATEGY:
# - User must explicitly approve each execution (not auto-approved)
# - Useful for ad-hoc tasks but not automation
# - Provides flexibility while maintaining baseline security
#

{ ... }:

let
  # === SYSTEM SCRIPTING & EXECUTION ===
  # osascript can execute arbitrary AppleScript and control other applications
  # High risk: can access sensitive data, simulate user input, modify system state
  systemScriptCommands = [
    "Bash(osascript:*)"
    "Bash(osascript -e:*)"
  ];

  # === SYSTEM INFORMATION DISCLOSURE ===
  # system_profiler reveals detailed hardware/software configuration
  # log show exposes macOS unified logging (system/app data)
  # Moderate risk: can leak system information useful for targeting attacks
  systemInfoDisclosureCommands = [
    "Bash(system_profiler:*)"
    "Bash(log show:*)"
  ];

  # === SYSTEM CONFIGURATION ACCESS ===
  # defaults read can expose sensitive macOS system settings
  # Moderate risk: settings may contain security-relevant information
  macosConfigCommands = [
    "Bash(defaults read:*)"
  ];

  # === VERSION CONTROL DESTRUCTIVE OPERATIONS ===
  # git reset can discard commits and lose work if misused
  # Moderate risk: can lose uncommitted/committed work
  gitDestructiveOperations = [
    "Bash(git reset:*)"
  ];

  # === SECURITY & CRYPTOGRAPHY ===
  # gpg can sign/encrypt/decrypt files, manage keys
  # chown can change file ownership (can cause permission issues)
  securityOperations = [
    "Bash(gpg:*)"
    "Bash(chown:*)"
  ];

  # === FILE SYSTEM OPERATIONS ===
  # These can modify file permissions, delete files, copy/move with overwrites
  # High risk: unintended file modification, data loss, permission changes
  # NOTE: sudo rm is in DENY list (absolutely catastrophic), not here
  dangerousFileOperations = [
    # Permissions
    "Bash(chmod:*)"

    # File deletion (non-sudo variants)
    "Bash(rm:*)"
    "Bash(rmdir:*)"

    # File copy/move (can overwrite)
    "Bash(cp:*)"
    "Bash(mv:*)"

    # Text processing with modification capability
    "Bash(sed:*)"      # Can use -i for in-place editing
    "Bash(awk:*)"      # Can modify files in complex ways
  ];

  # === CONTAINER OPERATIONS ===
  # docker exec and docker run allow arbitrary code execution in containers
  # Very high risk: can access container files, run malicious code, escalate
  dockerPrivilegedOperations = [
    "Bash(docker exec:*)"
    "Bash(docker run:*)"
  ];

  # === KUBERNETES CLUSTER MODIFICATION ===
  # These operations modify cluster state and can break production systems
  kubernetesDestructiveOperations = [
    "Bash(kubectl apply:*)"      # Apply configuration changes
    "Bash(kubectl create:*)"     # Create new resources
    "Bash(kubectl delete:*)"     # Delete resources
    "Bash(kubectl set:*)"        # Modify resource fields
    "Bash(kubectl patch:*)"      # Patch resources
    "Bash(helm install:*)"       # Install Helm charts
    "Bash(helm upgrade:*)"       # Upgrade Helm releases
    "Bash(helm uninstall:*)"     # Uninstall Helm releases
  ];

  # === CLOUD INFRASTRUCTURE OPERATIONS ===
  # These can modify, delete, or access cloud resources
  # Very high risk: data loss, service disruption, cost implications
  awsDestructiveOperations = [
    # S3 write operations (can overwrite, delete, exfiltrate)
    "Bash(aws s3 cp:*)"
    "Bash(aws s3 sync:*)"
    "Bash(aws s3 rm:*)"

    # EC2 operations (can terminate instances)
    "Bash(aws ec2 run-instances:*)"
    "Bash(aws ec2 terminate-instances:*)"

    # Lambda execution (can trigger side effects)
    "Bash(aws lambda invoke:*)"

    # CloudFormation (can delete stacks)
    "Bash(aws cloudformation delete-stack:*)"
  ];

  # === ARBITRARY PACKAGE EXECUTION ===
  # npx can download and execute arbitrary packages from npm registry
  # Very high risk: arbitrary code execution from untrusted source
  packageExecutionCommands = [
    "Bash(npx:*)"
  ];

  # === DATABASE OPERATIONS ===
  # These allow arbitrary SQL execution and database modifications
  # High risk: data loss, corruption, extraction
  databaseModificationCommands = [
    "Bash(sqlite3:*)"      # Can execute arbitrary SQL
    "Bash(mongosh:*)"      # MongoDB shell - can modify data
  ];

in
{
  # Export the ask list (all commands requiring user approval)
  askList = systemScriptCommands
    ++ systemInfoDisclosureCommands
    ++ macosConfigCommands
    ++ gitDestructiveOperations
    ++ securityOperations
    ++ dangerousFileOperations
    ++ dockerPrivilegedOperations
    ++ kubernetesDestructiveOperations
    ++ awsDestructiveOperations
    ++ packageExecutionCommands
    ++ databaseModificationCommands;
}
