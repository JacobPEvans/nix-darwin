# GitHub Copilot CLI Configuration
#
# This file defines directory trust and permission patterns for GitHub Copilot CLI.
#
# COPILOT CLI PERMISSION MODEL:
# - trusted_folders: List of directories where Copilot can operate
# - --allow-tool / --deny-tool: CLI flags for runtime permission control
#
# NOTE: Unlike Claude Code and Gemini CLI, Copilot CLI's config.json only
# contains trusted_folders. Permission controls are managed via command-line
# flags (--allow-tool, --deny-tool) which must be specified at runtime.
#
# CONFIGURATION LAYERS:
# 1. config.json (this file) - Directory trust model
# 2. CLI flags (documented below) - Runtime tool permissions
#
# PRINCIPLE OF LEAST PRIVILEGE:
# - Only trust directories you actively work in
# - Use --allow-tool and --deny-tool flags for fine-grained control
# - Default behavior requires approval for each tool execution

{ config, ... }:

let
  # User home directory
  homeDir = config.home.homeDirectory;

  # Trusted development directories
  # Add paths where you want Copilot to operate without directory confirmation
  trustedDevelopmentDirs = [
    "${homeDir}/projects"
    "${homeDir}/repos"
    "${homeDir}/workspace"
    "${homeDir}/src"
    "${homeDir}/dev"
    "${homeDir}/git"
  ];

  # Trusted configuration directories
  trustedConfigDirs = [
    "${homeDir}/.config/nix"
    "${homeDir}/.dotfiles"
    "${homeDir}/.config"
  ];

  # Generic home directory access
  # Allows Copilot to operate anywhere under home directory
  trustedHomeDir = [
    homeDir
  ];

in
{
  # Export trusted_folders list for config.json
  # Includes home dir for generic access across all user directories
  trusted_folders = trustedHomeDir ++ trustedDevelopmentDirs ++ trustedConfigDirs;

  # === COPILOT CLI FLAGS REFERENCE ===
  # These are NOT part of config.json - they must be passed as CLI arguments
  #
  # USAGE EXAMPLES:
  #
  # 1. Allow all tools except specific commands:
  #    copilot --allow-all-tools --deny-tool 'shell(rm)' --deny-tool 'shell(git push)'
  #
  # 2. Allow shell commands without approval:
  #    copilot --allow-tool 'shell'
  #
  # 3. Allow file writes without approval:
  #    copilot --allow-tool 'write'
  #
  # 4. Deny specific shell commands (supports glob patterns):
  #    copilot --deny-tool 'shell(rm)'
  #    copilot --deny-tool 'shell(npm run test:*)'
  #
  # 5. Deny tools from specific MCP servers:
  #    copilot --deny-tool 'My-MCP-Server(tool_name)'
  #
  # RECOMMENDED SAFE FLAGS:
  # These mirror Claude Code's permission philosophy

  # Safe read-only operations (always allow)
  recommendedAllowTools = [
    # Note: These are examples - actual implementation depends on your workflow
    # "shell(git status)"
    # "shell(git log)"
    # "shell(git diff)"
    # "shell(ls)"
    # "shell(cat)"
    # "shell(grep)"
  ];

  # Dangerous operations (always deny)
  # Mirrors claude-permissions.nix deny list
  recommendedDenyTools = [
    "shell(rm -rf /)"
    "shell(rm -rf /*)"
    "shell(rm -rf ~)"
    "shell(sudo rm)"
    "shell(sudo dd)"
    "shell(mkfs)"
    "shell(fdisk)"
    "shell(diskutil)"
    "shell(sudo su)"
    "shell(sudo -i)"
    "shell(sudo bash)"
    "shell(sudo -s)"
    "shell(nc -l)"
    "shell(ncat -l)"
    "shell(socat)"
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
    "shell(osascript)"
    "shell(npx)"
    "shell(docker exec)"
    "shell(docker run)"
    "shell(sqlite3)"
    "shell(mongosh)"
    "shell(aws s3 rm)"
    "shell(aws ec2 terminate-instances)"
    "shell(aws lambda invoke)"
    "shell(aws cloudformation delete-stack)"
    "shell(kubectl delete)"
    "shell(kubectl apply)"
    "shell(kubectl create)"
    "shell(helm uninstall)"
    # Terraform/Terragrunt destructive operations
    "shell(terraform apply)"
    "shell(terraform destroy)"
    "shell(terragrunt apply)"
    "shell(terragrunt destroy)"
    "shell(terragrunt run-all apply)"
    "shell(terragrunt run-all destroy)"
  ];

  # === IMPLEMENTATION NOTES ===
  #
  # To use these flags in practice, you have several options:
  #
  # 1. Shell alias (add to ~/.zshrc or Nix shell config):
  #    alias copilot-safe='copilot --allow-all-tools --deny-tool "shell(rm -rf)"'
  #
  # 2. Environment variable (if Copilot supports config via env):
  #    export COPILOT_FLAGS="--allow-all-tools --deny-tool 'shell(rm -rf)'"
  #
  # 3. Wrapper script:
  #    Create a script that calls copilot with your preferred flags
  #
  # 4. Per-session basis:
  #    Manually add flags when invoking copilot
  #
  # The config.json file (managed by this Nix configuration) only handles
  # trusted_folders. All tool-level permissions require runtime CLI flags.
}
