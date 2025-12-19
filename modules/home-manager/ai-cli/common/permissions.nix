# Unified AI CLI Permission Definitions
#
# Single source of truth for command permissions across all AI tools.
# Each tool uses formatters to convert these to their specific format.
#
# STRUCTURE:
# - allow: Auto-approved commands (imported from allow.nix)
# - deny: Permanently blocked, catastrophic operations
# - directories: Shared directory trust configuration
# - toolSpecific: Non-shell tool identifiers
#
# TOOL FORMATS (applied by formatters.nix):
# - Claude: Bash(cmd:*), Read(**), etc.
# - Gemini: ShellTool(cmd), ReadFileTool, etc.
# - Copilot: shell(cmd) patterns (runtime flags)
# - OpenCode: TBD

{
  lib,
  config,
  ...
}:

let
  homeDir = config.home.homeDirectory;
in
{
  # Auto-approved commands (imported from separate file for size)
  allow = import ./allow.nix { };

  # Denied commands (catastrophic, permanently blocked)
  deny = {
    fileDestruction = [
      "rm -rf /"
      "rm -rf /*"
      "rm -rf ~"
      "rm -fr /"
      "rm -fr /*"
      "rm --recursive --force /"
      "rm --recursive --force /*"
    ];

    httpWrite = [
      "curl -X POST"
      "curl -X PUT"
      "curl -X DELETE"
      "curl -X PATCH"
      "curl --request POST"
      "curl --request PUT"
      "curl --request DELETE"
      "curl --request PATCH"
      "curl -d"
      "curl --data"
    ];

    systemDestruction = [
      "sudo rm"
      "sudo dd"
      "mkfs"
      "fdisk"
      "diskutil"
    ];

    privilegeEscalation = [
      "sudo su"
      "sudo -i"
      "sudo bash"
      "sudo -s"
    ];

    reverseShells = [
      "nc -l"
      "ncat -l"
      "socat"
    ];

    gitDangerous = [
      "git push --force origin main"
      "git push --force origin master"
      "git push -f origin main"
      "git push -f origin master"
    ];
  };

  # Trusted directories
  directories = {
    development = [
      "${homeDir}/projects"
      "${homeDir}/repos"
      "${homeDir}/workspace"
      "${homeDir}/src"
      "${homeDir}/dev"
      "${homeDir}/git"
    ];

    config = [
      "${homeDir}/.config/nix"
      "${homeDir}/.dotfiles"
      "${homeDir}/.config"
      "${homeDir}/.claude"
    ];

    home = [ homeDir ];
  };

  # Tool-specific identifiers (non-shell)
  toolSpecific = {
    gemini.core = [
      "ReadFileTool"
      "GlobTool"
      "GrepTool"
      "WebFetchTool"
    ];

    claude.core = [
      "Read"
      "Glob"
      "Grep"
      "WebFetch"
      "WebSearch"
    ];
  };
}
