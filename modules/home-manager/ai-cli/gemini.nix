# Gemini CLI Configuration
#
# Returns home.file entries for Google Gemini Code Assist CLI.
# Imported by home.nix for clean separation of AI CLI configs.
#
# Configuration format:
# - coreTools: List of allowed built-in tools and shell commands
# - excludeTools: List of permanently blocked commands
#
# Permission files:
# - gemini-permissions-allow.nix - coreTools (allowed commands)
# - gemini-permissions-deny.nix - excludeTools (blocked commands)
# - gemini-permissions-ask.nix - Reference only (Gemini doesn't support ask mode)

{ config, ... }:

let
  geminiAllow = import ../permissions/gemini-permissions-allow.nix { inherit config; };
  geminiDeny = import ../permissions/gemini-permissions-deny.nix { };
in
{
  ".gemini/settings.json".text = builtins.toJSON {
    # Allowed tools (safe, read-focused operations)
    coreTools = geminiAllow.coreTools;

    # Blocked tools (catastrophic operations)
    excludeTools = geminiDeny.excludeTools;

    # Additional Gemini CLI settings can be added here
    # See: https://google-gemini.github.io/gemini-cli/docs/get-started/configuration.html
  };
}
