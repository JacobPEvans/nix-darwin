# Claude Code Plugin Registry
#
# Generates known_marketplaces.json and installed_plugins.json.
# Supports hybrid mode: Nix-managed + runtime plugins coexist.
{ config, lib, ... }:

let
  cfg = config.programs.claude;

  # Generate registry entry for a marketplace
  mkMarketplaceEntry = name: marketplace: {
    source = {
      inherit (marketplace.source) type url;
    };
    # For Nix-managed: point to store path; for runtime: use standard location
    installLocation =
      if marketplace.flakeInput != null
      then toString marketplace.flakeInput
      else "${config.home.homeDirectory}/.claude/plugins/marketplaces/${lib.replaceStrings ["/"] ["-"] name}";
    lastUpdated = "@ACTIVATION_TIME@";
  };

  # Build the full registry
  knownMarketplaces = lib.mapAttrs mkMarketplaceEntry cfg.plugins.marketplaces
    // lib.optionalAttrs cfg.plugins.allowRuntimeInstall {
      "local/experimental" = {
        source = { type = "local"; url = "~/.claude/plugins/local"; };
        installLocation = "${config.home.homeDirectory}/.claude/plugins/marketplaces/local";
        managedBy = "runtime";
      };
    };

  # Installed plugins registry (schema version tracking)
  installedPlugins = {
    version = cfg.features.pluginSchemaVersion;
    plugins = { };  # Claude Code populates this at runtime
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
