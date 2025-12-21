# OpenCode Configuration
#
# Returns home.file entries for OpenCode AI coding agent.
# Imported by home.nix for clean separation of AI CLI configs.
#
# OpenCode is a provider-agnostic AI coding agent that supports:
# - Claude (Anthropic)
# - GPT-4 (OpenAI)
# - Gemini (Google)
# - Local models (Ollama)
#
# Configuration format:
# - theme: UI theme (dark, light, auto)
# - model.default: Default AI model to use
# - permissions: Uses unified permission system from common/permissions.nix
#
# Reference: https://github.com/sst/opencode

{
  config,
  lib,
  pkgs,
  ...
}:

let
  # OpenCode settings object
  settings = {
    # UI configuration
    theme = "auto";

    # Model configuration
    model = {
      # Default to Claude Sonnet 4.5 (fast, capable)
      default = "claude-sonnet-4-20250514";
    };

    # TODO: Add shared permissions once OpenCode permission format is determined
    # Will use common/permissions.nix and common/formatters.nix when needed
  };

  # Generate pretty-printed JSON using a derivation with jq
  # This improves readability for debugging and matches other AI CLI configs
  settingsJson =
    pkgs.runCommand "opencode-settings.json"
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
  ".config/opencode/opencode.json".source = settingsJson;
}
