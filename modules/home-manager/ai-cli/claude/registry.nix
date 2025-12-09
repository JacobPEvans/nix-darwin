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

in {
  config = lib.mkIf cfg.enable {
    home.file = {
      ".claude/plugins/known_marketplaces.json".text =
        builtins.toJSON knownMarketplaces;

      ".claude/plugins/installed_plugins.json".text =
        builtins.toJSON installedPlugins;
    };
  };
}
