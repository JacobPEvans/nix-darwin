# Claude Registry Pure Functions
#
# Pure Nix functions for generating Claude Code registry structures.
# Used by both the home-manager module and CI validation.
# No derivations or impure operations - works cross-platform.
#
# IMPORTANT: toClaudeMarketplaceFormat is the SINGLE SOURCE OF TRUTH for
# marketplace format transformation. All modules (settings.nix, claude-settings.nix)
# MUST import and use this function to ensure consistency.
{
  lib ? import <nixpkgs/lib>,
}:

let
  # ==========================================================================
  # SINGLE SOURCE OF TRUTH: Marketplace Format Transformation
  # ==========================================================================
  # Claude Code expects: { source: { source: "github", repo: "owner/repo" } }
  # For non-github sources, use url instead of repo.
  #
  # Usage: Import this function in any module that needs to transform marketplaces:
  #   claudeRegistry = import ../../lib/claude-registry.nix { inherit lib; };
  #   transformed = claudeRegistry.toClaudeMarketplaceFormat name marketplace;
  #
  toClaudeMarketplaceFormat = name: m: {
    source =
      if m.source.type == "github" || m.source.type == "git" then
        {
          source = "github";
          repo = name; # "owner/repo" format (the key itself)
        }
      else
        {
          source = m.source.type;
          inherit (m.source) url;
        };
  };
in
{
  # Export the transformation function for use by other modules
  inherit toClaudeMarketplaceFormat;
  # Generate the full known_marketplaces.json structure
  # Matches native Claude Code format exactly
  mkKnownMarketplaces =
    {
      marketplaces,
      homeDir ? "/home/user",
      allowRuntimeInstall ? true,
    }:
    let
      # Extract marketplace name from the identifier
      # e.g., "anthropics/claude-plugins-official" -> "claude-plugins-official"
      #       "org/team/repo" -> "repo"
      getMarketplaceName = name: lib.last (lib.splitString "/" name);

      # Convert marketplace config to native format
      # Uses toClaudeMarketplaceFormat for consistent source formatting
      toNativeFormat =
        name: m:
        let
          marketplaceName = getMarketplaceName name;
          # Native format uses local paths, not Nix store
          localPath = "${homeDir}/.claude/plugins/marketplaces/${marketplaceName}";
          # Reuse single source of truth for marketplace format
          formatted = toClaudeMarketplaceFormat name m;
        in
        lib.nameValuePair marketplaceName {
          # Field order matches native: source, installLocation, lastUpdated
          inherit (formatted) source;
          installLocation = localPath;
          lastUpdated = "2025-12-08T00:00:00.000Z";
        };
    in
    lib.listToAttrs (lib.mapAttrsToList toNativeFormat marketplaces)
    // lib.optionalAttrs allowRuntimeInstall {
      "local" = {
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
  mkInstalledPlugins =
    {
      schemaVersion ? 1,
    }:
    {
      version = schemaVersion;
      plugins = { };
    };

  # Generate settings.json structure (pure, no derivations)
  mkSettings =
    {
      schemaUrl ? "https://json.schemastore.org/claude-code-settings.json",
      alwaysThinkingEnabled ? true,
      permissions ? {
        allow = [ ];
        deny = [ ];
        ask = [ ];
      },
      additionalDirectories ? [ ],
      marketplaces ? { },
      enabledPlugins ? { },
      mcpServers ? { },
    }:
    {
      "$schema" = schemaUrl;
      inherit alwaysThinkingEnabled;
      permissions = {
        allow = permissions.allow or [ ];
        deny = permissions.deny or [ ];
        ask = permissions.ask or [ ];
      };
      inherit additionalDirectories;
      # Uses toClaudeMarketplaceFormat (single source of truth)
      extraKnownMarketplaces = lib.mapAttrs toClaudeMarketplaceFormat marketplaces;
      inherit enabledPlugins;
      mcpServers = lib.filterAttrs (_: s: !(s.disabled or false)) mcpServers;
    };
}
