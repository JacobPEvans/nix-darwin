# Claude Registry Pure Functions
#
# Pure Nix functions for generating Claude Code registry structures.
# Used by both the home-manager module and CI validation.
# No derivations or impure operations - works cross-platform.
{ lib ? import <nixpkgs/lib> }:

{
  # Generate the full known_marketplaces.json structure
  mkKnownMarketplaces = { marketplaces, homeDir ? "/home/user", allowRuntimeInstall ? true }:
    lib.mapAttrs (name: m: {
      source = { inherit (m.source) type url; };
      installLocation =
        if m.flakeInput or null != null
        then toString m.flakeInput
        else "${homeDir}/.claude/plugins/marketplaces/${lib.replaceStrings ["/"] ["-"] name}";
      lastUpdated = "@ACTIVATION_TIME@";
    }) marketplaces
    // lib.optionalAttrs allowRuntimeInstall {
      "local/experimental" = {
        source = { type = "local"; url = "~/.claude/plugins/local"; };
        installLocation = "${homeDir}/.claude/plugins/marketplaces/local";
        managedBy = "runtime";
      };
    };

  # Generate installed_plugins.json structure
  mkInstalledPlugins = { schemaVersion ? 1 }: {
    version = schemaVersion;
    plugins = { };
  };

  # Generate settings.json structure (pure, no derivations)
  mkSettings = {
    schemaUrl ? "https://json.schemastore.org/claude-code-settings.json",
    alwaysThinkingEnabled ? true,
    permissions ? { allow = []; deny = []; ask = []; },
    additionalDirectories ? [],
    marketplaces ? {},
    enabledPlugins ? {},
    mcpServers ? {}
  }: {
    "$schema" = schemaUrl;
    inherit alwaysThinkingEnabled;
    permissions = {
      allow = permissions.allow or [];
      deny = permissions.deny or [];
      ask = permissions.ask or [];
    };
    inherit additionalDirectories;
    extraKnownMarketplaces = lib.mapAttrs (_: m: {
      source = { inherit (m.source) type url; };
    }) marketplaces;
    inherit enabledPlugins;
    mcpServers = lib.filterAttrs (_: s: !(s.disabled or false)) mcpServers;
  };
}
