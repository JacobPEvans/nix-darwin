# Claude Registry Pure Functions
#
# Pure Nix functions for generating Claude Code registry structures.
# Used by both the home-manager module and CI validation.
# No derivations or impure operations - works cross-platform.
{ lib ? import <nixpkgs/lib> }:

{
  # Generate the full known_marketplaces.json structure
  mkKnownMarketplaces =
    { marketplaces, homeDir ? "/home/user", allowRuntimeInstall ? true }:
    lib.mapAttrs (name: m: {
      source = {
        source = m.source.type;
        url = m.source.url;
      };
      installLocation = if m.flakeInput or null != null then
        toString m.flakeInput
      else
        "${homeDir}/.claude/plugins/marketplaces/${
          lib.replaceStrings [ "/" ] [ "-" ] name
        }";
      lastUpdated = "2025-12-08T00:00:00.000Z"; # Static - file is in nix store
    }) marketplaces // lib.optionalAttrs allowRuntimeInstall {
      "local/experimental" = {
        source = {
          source = "directory";
          path = "~/.claude/plugins/local";
        };
        installLocation = "${homeDir}/.claude/plugins/marketplaces/local";
        lastUpdated = "2025-12-08T00:00:00.000Z";
        managedBy = "runtime";
      };
    };

  # Generate installed_plugins.json structure
  mkInstalledPlugins = { schemaVersion ? 1 }: {
    version = schemaVersion;
    plugins = { };
  };

  # Generate settings.json structure (pure, no derivations)
  mkSettings =
    { schemaUrl ? "https://json.schemastore.org/claude-code-settings.json"
    , alwaysThinkingEnabled ? true, permissions ? {
      allow = [ ];
      deny = [ ];
      ask = [ ];
    }, additionalDirectories ? [ ], marketplaces ? { }, enabledPlugins ? { }
    , mcpServers ? { } }: {
      "$schema" = schemaUrl;
      inherit alwaysThinkingEnabled;
      permissions = {
        allow = permissions.allow or [ ];
        deny = permissions.deny or [ ];
        ask = permissions.ask or [ ];
      };
      inherit additionalDirectories;
      extraKnownMarketplaces =
        lib.mapAttrs (_: m: { source = { inherit (m.source) type url; }; })
        marketplaces;
      inherit enabledPlugins;
      mcpServers = lib.filterAttrs (_: s: !(s.disabled or false)) mcpServers;
    };
}
