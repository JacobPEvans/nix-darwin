# Claude Code Plugin Management
#
# Symlinks Nix-managed plugin directories from flake inputs.
# Runtime plugins are unaffected - they live in separate directories.
{ config, lib, ... }:

let
  cfg = config.programs.claude;

  # Extract marketplace name from "owner/repo" format
  # e.g., "anthropics/claude-plugins-official" -> "claude-plugins-official"
  getMarketplaceName =
    name:
    let
      parts = lib.splitString "/" name;
    in
    if builtins.length parts > 1 then builtins.elemAt parts 1 else name;

  # Create symlink entries for Nix-managed marketplaces
  nixManagedMarketplaces = lib.filterAttrs (_: m: m.flakeInput != null) cfg.plugins.marketplaces;

  marketplaceSymlinks = lib.mapAttrs' (
    name: marketplace:
    lib.nameValuePair ".claude/plugins/marketplaces/${getMarketplaceName name}" {
      source = marketplace.flakeInput;
    }
  ) nixManagedMarketplaces;

in
{
  config = lib.mkIf cfg.enable { home.file = marketplaceSymlinks; };
}
