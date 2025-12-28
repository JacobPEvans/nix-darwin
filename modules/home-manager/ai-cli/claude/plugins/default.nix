# Claude Code Plugins - Main Configuration
#
# Modular plugin configuration organized by category:
# - marketplaces.nix: All available plugin marketplaces
# - official.nix: Official Anthropic plugins
# - community.nix: Community marketplace plugins
# - infrastructure.nix: Infrastructure, DevOps, and cloud operations
# - development.nix: Software development and engineering tools
#
# Each module exports an enabledPlugins attrset that gets merged.
# The marketplaces module exports a marketplaces attrset.

{ lib, ... }:

let
  # Import all plugin category modules
  marketplacesModule = import ./marketplaces.nix { inherit lib; };
  officialModule = import ./official.nix { };
  communityModule = import ./community.nix { };
  infrastructureModule = import ./infrastructure.nix { };
  developmentModule = import ./development.nix { };

  # Merge all enabled plugins from category modules
  enabledPlugins =
    officialModule.enabledPlugins
    // communityModule.enabledPlugins
    // infrastructureModule.enabledPlugins
    // developmentModule.enabledPlugins;
in
{
  # Return the complete plugin configuration
  inherit enabledPlugins;
  inherit (marketplacesModule) marketplaces;
}
