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
      "git -C"
    ];

    gitHookBypasses = [
      "git commit --no-verify"
      "git commit -n"
      "git merge --no-verify"
      "git cherry-pick --no-verify"
      "git rebase --no-verify"
      "git config core.hooksPath"
      "git -c core.hooksPath"
      "pre-commit uninstall"
      "rm .git/hooks"
      "rm -rf .git/hooks"
      "rm .git/hooks/"
      "rm -rf .git/hooks/"
      "chmod -x .git/hooks/"
    ];

    shellDangerous = [
      "xargs"
      "for "
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

    claude = {
      # Core tools with glob patterns
      core = [
        "Read(**)"
        "Glob(**)"
        "Grep(**)"
        "WebSearch"
        "TodoWrite"
        "TodoRead"
        "SlashCommand(**)"
      ];

      # WebFetch with allowed domains
      webFetch = [
        "WebFetch(domain:github.com)"
        "WebFetch(domain:githubusercontent.com)"
        "WebFetch(domain:anthropic.com)"
        "WebFetch(domain:nixos.org)"
        "WebFetch(domain:hashicorp.com)"
        "WebFetch(domain:terraform.io)"
        "WebFetch(domain:geminicli.com)"
        "WebFetch(domain:google.dev)"
        "WebFetch(domain:npmjs.com)"
        "WebFetch(domain:docker.com)"
        "WebFetch(domain:kubernetes.io)"
        "WebFetch(domain:python.org)"
        "WebFetch(domain:pypi.org)"
        "WebFetch(domain:readthedocs.io)"
        "WebFetch(domain:rust-lang.org)"
        "WebFetch(domain:typescriptlang.org)"
        "WebFetch(domain:stackoverflow.com)"
        "WebFetch(domain:mozilla.org)"
        "WebFetch(domain:openai.com)"
        "WebFetch(domain:raycast.com)"
        "WebFetch(domain:apple.com)"
        "WebFetch(domain:google.com)"
        "WebFetch(domain:github.io)"
      ];

      # Special read patterns
      read = [
        "Read(//nix/store/**)"
      ];

      # Deny patterns for sensitive files (Claude-specific Read tool)
      denyRead = [
        "Read(.env)"
        "Read(.env.*)"
        "Read(**/.env)"
        "Read(**/.env.*)"
        "Read(**/secrets/**)"
        "Read(**/credentials/**)"
        "Read(**/*_rsa)"
        "Read(**/*_dsa)"
        "Read(**/*_ecdsa)"
        "Read(**/*_ed25519)"
        "Read(~/.ssh/id_*)"
        "Read(~/.aws/credentials)"
        "Read(~/.gnupg/**)"
      ];
    };
  };
}
