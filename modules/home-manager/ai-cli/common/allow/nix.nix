# Nix Package Manager Commands
#
# Auto-approved nix commands including flakes, builds, darwin-rebuild.
# Imported by allow.nix - do not use directly.

_:

{
  # --- Nix Package Manager ---
  nix = {
    read = [
      "nix --version"
      "nix show-config"
      "nix search"
      "nix search nixpkgs"
      "nix eval"
      "nix path-info"
      "nix why-depends"
      "nix hash"
    ];
    flake = [
      "nix flake update"
      "nix flake metadata"
      "nix flake show"
      "nix flake check"
    ];
    build = [
      "nix build"
      "nix develop"
      "nix shell"
      "nix run"
      "nix repl"
    ];
    store = [
      "nix store ls"
      "nix store path-info"
      "nix store verify"
      "nix store diff-closures"
      "nix-store -q"
      "nix-store --query"
      "nix-store --verify"
      "nix-store --gc"
    ];
    legacy = [
      "nix-env"
      "nix-env -q"
      "nix-env --query"
      "nix profile"
      "nix-shell"
      "nix-instantiate"
      "nix-collect-garbage"
      "nix-prefetch-url"
      "nix-prefetch-git"
      "nix-locate"
      "nix-tree"
      "nix-diff"
    ];
    darwin = [
      "darwin-rebuild switch"
      "darwin-rebuild build"
      "darwin-rebuild --list-generations"
      "darwin-rebuild --rollback"
      "sudo darwin-rebuild"
    ];
    quality = [
      "nixfmt-rfc-style --version"
      "nixfmt"
      "nix fmt"
      "statix check"
      "deadnix"
    ];
  };

  # --- Homebrew ---
  homebrew = [
    "brew list"
    "brew search"
    "brew info"
    "brew --version"
    "brew doctor"
    "brew config"
    "brew outdated"
    "brew deps"
  ];
}
