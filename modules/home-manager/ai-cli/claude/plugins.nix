# Claude Code Plugin Management
#
# Symlinks Nix-managed plugin directories from flake inputs.
# Runtime plugins are unaffected - they live in separate directories.
{ config, lib, ... }:

let
  cfg = config.programs.claude;

  # Create symlink entries for Nix-managed marketplaces
  nixManagedMarketplaces = lib.filterAttrs
    (_: m: m.flakeInput != null)
    cfg.plugins.marketplaces;

  marketplaceSymlinks = lib.mapAttrs' (name: marketplace:
    lib.nameValuePair
      ".claude/plugins/marketplaces/${lib.replaceStrings ["/"] ["-"] name}"
      { source = marketplace.flakeInput; }
  ) nixManagedMarketplaces;

in {
  config = lib.mkIf cfg.enable {
    home.file = marketplaceSymlinks;
  };
}
