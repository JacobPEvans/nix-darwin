# Claude Code Statusline Package Builder
#
# Shared derivation for building claude-code-statusline from source.
# Used by both the legacy statusline module and theme-specific modules.
{ lib, pkgs }:

{
  # Build claude-code-statusline package from source
  mkStatuslinePackage =
    source:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "claude-code-statusline";
      version = "2.1.0";
      src = source;

      nativeBuildInputs = [ pkgs.makeWrapper ];
      # Note: NOT including coreutils - script expects macOS stat, not GNU stat
      buildInputs = [
        pkgs.bash
        pkgs.jq
        pkgs.git
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/share/claude-code-statusline $out/bin

        # Copy all source files (statusline.sh, lib/, examples/)
        cp -r . $out/share/claude-code-statusline/

        # Create wrapper - add bash/jq/git/bun (for ccusage via bunx)
        # The statusline script uses 'bunx ccusage' for cost tracking
        makeWrapper $out/share/claude-code-statusline/statusline.sh $out/bin/claude-code-statusline \
          --prefix PATH : ${
            lib.makeBinPath [
              pkgs.bash
              pkgs.jq
              pkgs.git
              pkgs.bun
            ]
          } \
          --set STATUSLINE_HOME $out/share/claude-code-statusline

        chmod +x $out/bin/claude-code-statusline
        runHook postInstall
      '';

      meta = with lib; {
        description = "Configurable statusline for Claude Code with git and cost tracking";
        homepage = "https://github.com/rz1989s/claude-code-statusline";
        license = licenses.mit;
        platforms = platforms.all;
        mainProgram = "claude-code-statusline";
      };
    };
}
