# Claude Code Plugin Registry
#
# Generates known_marketplaces.json for Claude Code.
#
# CRITICAL: lastUpdated Field
# ============================================================================
# Generated at build time using printf's %T format (requires bash 4.2+)
# Format: ISO 8601 with milliseconds (YYYY-MM-DDTHH:MM:SS.000Z)
# Example: "2025-12-31T16:44:10.000Z"
#
# This is cosmetic metadata - Claude updates it at runtime anyway, but we
# generate a valid timestamp to avoid magic dates like "1970-01-01".
# ============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.claude;

  # Import pure registry functions from lib
  # Pass current timestamp for lastUpdated field (generated at build time)
  claudeRegistryLib = import ../../../../lib/claude-registry.nix {
    inherit lib;
    # Generate ISO 8601 timestamp at build time via bash printf
    lastUpdated = builtins.readFile (
      pkgs.runCommand "timestamp" { } "printf '%(%Y-%m-%dT%H:%M:%S.000Z)T' -1 > $out"
    );
  };

  # Build the full registry using lib function
  knownMarketplaces = claudeRegistryLib.mkKnownMarketplaces {
    inherit (cfg.plugins) marketplaces allowRuntimeInstall;
    homeDir = config.home.homeDirectory;
  };

  # Generate pretty-printed JSON using a derivation with jq
  # This improves readability for debugging and matches claude settings.json format
  marketplacesJson =
    pkgs.runCommand "known_marketplaces.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
        json = builtins.toJSON knownMarketplaces;
        passAsFile = [ "json" ];
      }
      ''
        jq '.' "$jsonPath" > $out
      '';

in
{
  config = lib.mkIf cfg.enable {
    home.file = {
      # Marketplace sources - managed by Nix configuration (pretty-printed)
      # Uses force = true to overwrite any existing files (git provides version control)
      ".claude/plugins/known_marketplaces.json" = {
        source = marketplacesJson;
        force = true;
      };

      # NOTE: installed_plugins.json is NOT managed by Nix
      # Claude Code auto-creates this file on first plugin installation.
      # It's runtime state that Claude updates when plugins are installed/enabled.
      # Managing it with Nix causes rebuild conflicts since Claude overwrites it.
    };
  };
}
