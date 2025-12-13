# Claude Code Plugin Registry
#
# Generates known_marketplaces.json and installed_plugins.json.
# Supports hybrid mode: Nix-managed + runtime plugins coexist.
# Uses pure functions from lib/claude-registry.nix for DRY.
{ config, lib, ... }:

let
  cfg = config.programs.claude;

  # Import pure registry functions from lib
  claudeRegistryLib = import ../../../../lib/claude-registry.nix { inherit lib; };

  # Build the full registry using lib function
  knownMarketplaces = claudeRegistryLib.mkKnownMarketplaces {
    marketplaces = cfg.plugins.marketplaces;
    homeDir = config.home.homeDirectory;
    allowRuntimeInstall = cfg.plugins.allowRuntimeInstall;
  };

  # Installed plugins registry using lib function
  installedPlugins = claudeRegistryLib.mkInstalledPlugins {
    schemaVersion = cfg.features.pluginSchemaVersion;
  };

in
{
  config = lib.mkIf cfg.enable {
    home.file = {
      # Marketplace sources - managed by Nix configuration
      ".claude/plugins/known_marketplaces.json".text = builtins.toJSON knownMarketplaces;

      # NOTE: installed_plugins.json is NOT managed by Nix
      # Claude Code auto-creates this file on first plugin installation.
      # It's runtime state that Claude updates when plugins are installed/enabled.
      # Managing it with Nix causes rebuild conflicts since Claude overwrites it.
    };
  };
}
