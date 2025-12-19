# Robbyrussell Theme - Claude Code Statusline
#
# Simple, clean statusline theme inspired by the robbyrussell oh-my-zsh theme.
# This is the current default implementation, extracted from the original statusline.nix.
#
# Features:
# - Lightweight and fast
# - Single-line display optimized for SSH/mobile
# - Git integration
# - Cost tracking via ccusage
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.claudeStatusline;

  # Import shared package builder
  inherit (import ./package.nix { inherit lib pkgs; }) mkStatuslinePackage;

in
{
  config = lib.mkIf (cfg.enable && cfg.theme == "robbyrussell") (
    let
      # Get source from legacy statusLine.enhanced.source for backward compatibility
      # TODO: This should eventually be moved to claudeStatusline.source
      legacyCfg = config.programs.claude.statusLine.enhanced;
      inherit (legacyCfg) source;

      statuslinePackage = mkStatuslinePackage source;

      # Config files - full (local) and mobile (SSH)
      configFull =
        if legacyCfg.configFile != null then legacyCfg.configFile else "${source}/examples/Config.toml";

      configMobile = legacyCfg.mobileConfigFile;
    in
    {
      # Install the statusline package
      home.packages = [ statuslinePackage ];

      # Deploy config files
      home.file = {
        # Full config (always deployed)
        ".claude/statusline/config-full.toml".source = configFull;
      }
      // lib.optionalAttrs (configMobile != null) {
        # Mobile config (only if specified)
        ".claude/statusline/config-mobile.toml".source = configMobile;
      };
    }
  );
}
