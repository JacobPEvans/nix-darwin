# Claude Code Plugin Registry
#
# Generates known_marketplaces.json and installed_plugins.json.
# Supports hybrid mode: Nix-managed + runtime plugins coexist.
# Uses pure functions from lib/claude-registry.nix for DRY.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.claude;

  # Import pure registry functions from lib
  claudeRegistryLib = import ../../../../lib/claude-registry.nix { inherit lib; };

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
      ".claude/plugins/known_marketplaces.json".source = marketplacesJson;

      # NOTE: installed_plugins.json is NOT managed by Nix
      # Claude Code auto-creates this file on first plugin installation.
      # It's runtime state that Claude updates when plugins are installed/enabled.
      # Managing it with Nix causes rebuild conflicts since Claude overwrites it.
    };
  };
}
