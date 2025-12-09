# Claude Code Statusline Module
#
# Builds and configures claude-code-statusline from flake input.
# Creates wrapper package and manages Config.toml symlink.
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.claude;
  homeDir = config.home.homeDirectory;

  # Build claude-code-statusline package from source
  statuslinePackage = pkgs.stdenvNoCC.mkDerivation {
    pname = "claude-code-statusline";
    version = "2.1.0";
    src = cfg.statusLine.enhanced.source;

    nativeBuildInputs = [ pkgs.makeWrapper ];
    buildInputs = [ pkgs.bash pkgs.jq pkgs.git pkgs.coreutils ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/claude-code-statusline $out/bin

      # Copy all source files (statusline.sh, lib/, examples/)
      cp -r . $out/share/claude-code-statusline/

      # Create wrapper that executes from source directory
      makeWrapper $out/share/claude-code-statusline/statusline.sh $out/bin/claude-code-statusline \
        --prefix PATH : ${lib.makeBinPath [ pkgs.bash pkgs.jq pkgs.git pkgs.coreutils ]} \
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

  # Config file (custom or default from source examples/)
  configSource = if cfg.statusLine.enhanced.configFile != null
    then cfg.statusLine.enhanced.configFile
    else "${cfg.statusLine.enhanced.source}/examples/Config.toml";

in {
  config = lib.mkIf (cfg.enable && cfg.statusLine.enable && cfg.statusLine.enhanced.enable) {
    # Install the statusline package
    home.packages = [ statuslinePackage ];

    # Symlink Config.toml to ~/.claude/statusline/
    home.file.".claude/statusline/Config.toml".source = configSource;
  };
}
