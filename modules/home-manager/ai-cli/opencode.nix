# OpenCode Configuration
#
# Returns home.file entries for OpenCode AI coding agent.
# Imported by home.nix for clean separation of AI CLI configs.
#
# OpenCode is an open-source, provider-agnostic AI coding agent:
# - Works with Claude, OpenAI, Google, or local models
# - Terminal-based with LSP support
# - Two built-in agents: "build" (full access) and "plan" (read-only)
# - MIT licensed
#
# Configuration format:
# - opencode.json: Contains theme, model, and other settings
# - Permissions: Uses unified permission system from common/permissions.nix
#
# Reference: https://github.com/opencode-ai/opencode

{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Import permissions (prepared for future use)
  # opencodeAllow = import ../permissions/opencode-permissions-allow.nix { inherit config lib; };
  # opencodeDeny = import ../permissions/opencode-permissions-deny.nix { inherit config lib; };

  # OpenCode settings object
  # Project repository: https://github.com/opencode-ai/opencode
  settings = {
    # Theme setting (auto follows terminal theme)
    theme = "auto";

    # Default model configuration
    model = {
      default = "claude-sonnet-4-5-20250514";
    };

    # Additional settings can be added here as OpenCode evolves
    # Permissions integration pending OpenCode's permission system design
  };

  # Generate pretty-printed JSON using a derivation with jq
  # This matches the pattern used by other AI CLI configs (e.g., gemini.nix, copilot.nix)
  settingsJson =
    pkgs.runCommand "opencode.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
        json = builtins.toJSON settings;
        passAsFile = [ "json" ];
      }
      ''
        jq '.' "$jsonPath" > $out
      '';
in
{
  # XDG config path: ~/.config/opencode/opencode.json
  ".config/opencode/opencode.json".source = settingsJson;
}
