# macOS Application Overlays
#
# Packages for macOS apps distributed as .dmg files that aren't in nixpkgs.
# Package definitions live in packages/ for nix-update compatibility.

_final: prev: {
  claudebar = prev.callPackage ../packages/claudebar.nix { };
}
