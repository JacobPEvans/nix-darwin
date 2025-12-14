# Nix quality checks - single source of truth for pre-commit and CI
# Used by flake.nix checks output, ensuring DRY principle
{
  pkgs,
  src,
}:
{
  # Check Nix formatting with nixfmt-rfc-style
  # Uses treefmt configured with nixfmt formatter
  # Copy source to writable $TMPDIR since treefmt needs to write temp files
  formatting = pkgs.runCommand "check-formatting" {
    nativeBuildInputs = [ pkgs.nixfmt-rfc-style ];
  } ''
    cp -r ${src} $TMPDIR/src
    chmod -R u+w $TMPDIR/src
    cd $TMPDIR/src
    ${pkgs.lib.getExe pkgs.treefmt} --fail-on-change --no-cache --formatters nixfmt .
    touch $out
  '';

  # Lint Nix files for anti-patterns and code smells
  # Catches common mistakes and suggests improvements
  statix = pkgs.runCommand "check-statix" { } ''
    cd ${src}
    ${pkgs.lib.getExe pkgs.statix} check .
    touch $out
  '';

  # Check for unused Nix code (dead bindings)
  # -L: ignore lambda pattern names (config, lib, pkgs are common in modules)
  # --fail: exit with error if unused bindings found
  deadnix = pkgs.runCommand "check-deadnix" { } ''
    cd ${src}
    ${pkgs.lib.getExe pkgs.deadnix} -L --fail .
    touch $out
  '';
}
