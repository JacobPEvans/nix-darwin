# Claude Code Statusline Module
#
# Builds and configures claude-code-statusline from flake input.
# Creates wrapper package and manages config files.
# Supports SSH detection for mobile-friendly single-line display.
# Uses bun for ccusage cost tracking integration.
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.claude;

  # Build claude-code-statusline package from source
  # Only evaluated when enhanced statusline is enabled
  mkStatuslinePackage = source:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "claude-code-statusline";
      version = "2.1.0";
      src = source;

      nativeBuildInputs = [ pkgs.makeWrapper ];
      # Note: NOT including coreutils - script expects macOS stat, not GNU stat
      buildInputs = [ pkgs.bash pkgs.jq pkgs.git ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/share/claude-code-statusline $out/bin

        # Copy all source files (statusline.sh, lib/, examples/)
        cp -r . $out/share/claude-code-statusline/

        # Create wrapper - add bash/jq/git/bun (for ccusage via bunx)
        # The statusline script uses 'bunx ccusage' for cost tracking
        makeWrapper $out/share/claude-code-statusline/statusline.sh $out/bin/claude-code-statusline \
          --prefix PATH : ${
            lib.makeBinPath [ pkgs.bash pkgs.jq pkgs.git pkgs.bun ]
          } \
          --set STATUSLINE_HOME $out/share/claude-code-statusline

        chmod +x $out/bin/claude-code-statusline
        runHook postInstall
      '';

      meta = with lib; {
        description = "Modular multi-line statusline for Claude Code";
        homepage = "https://github.com/rz1989s/claude-code-statusline";
        license = licenses.mit;
        platforms = platforms.all;
        mainProgram = "claude-code-statusline";
      };
    };

in {
  config = lib.mkIf
    (cfg.enable && cfg.statusLine.enable && cfg.statusLine.enhanced.enable) (let
      statuslinePackage = mkStatuslinePackage cfg.statusLine.enhanced.source;

      # Config files - full (local) and mobile (SSH)
      configFull = if cfg.statusLine.enhanced.configFile != null then
        cfg.statusLine.enhanced.configFile
      else
        "${cfg.statusLine.enhanced.source}/examples/Config.toml";

      configMobile = cfg.statusLine.enhanced.mobileConfigFile;
    in {
      # Export the package for settings.nix to reference
      programs.claude.statusLine.enhanced.package = statuslinePackage;

      # Install the statusline package
      home.packages = [ statuslinePackage ];

      # Deploy config files
      home.file = {
        # Full config (always deployed)
        ".claude/statusline/config-full.toml".source = configFull;
      } // lib.optionalAttrs (configMobile != null) {
        # Mobile config (only if specified)
        ".claude/statusline/config-mobile.toml".source = configMobile;
      };
    });
}
