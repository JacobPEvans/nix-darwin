# Gemini CLI Configuration
#
# Returns home.file entries for Google Gemini Code Assist CLI.
# Imported by home.nix for clean separation of AI CLI configs.
#
# Configuration format:
# - coreTools: List of allowed built-in tools and shell commands
# - excludeTools: List of permanently blocked commands
#
# See home/gemini-permissions.nix for categorized command lists

{ config, ... }:

let
  geminiPerms = import ../permissions/gemini-permissions.nix { inherit config; };
in
{
  ".gemini/settings.json".text = builtins.toJSON {
    # Allowed tools (safe, read-focused operations)
    coreTools = geminiPerms.coreTools;

    # Blocked tools (catastrophic operations)
    excludeTools = geminiPerms.excludeTools;

    # Additional Gemini CLI settings can be added here
    # See: https://google-gemini.github.io/gemini-cli/docs/get-started/configuration.html
  };
}
