# AI Development Tools
#
# Linters, formatters, and utilities specifically for AI coding workflows.
# These tools are NOT general-purpose development tools.
#
# ============================================================================
# PACKAGE HIERARCHY (STRICT - NO EXCEPTIONS)
# ============================================================================
#
# ALWAYS follow this order when choosing how to install a package:
#
# 1. **nixpkgs** (ALWAYS FIRST, NO EXCEPTIONS)
#    - Check: nix search nixpkgs <package>
#    - Use if package exists and is reasonably up-to-date
#    - Benefits: Binary cache, security updates, integration
#    - Example: claude-code, claude-monitor, bun
#
# 2. **homebrew** (ONLY if not in nixpkgs)
#    - Fallback for packages missing from nixpkgs
#    - Check: brew search <package>
#    - Add to modules/darwin/homebrew.nix with clear justification
#    - Document WHY homebrew is needed (not in nixpkgs, severely outdated, etc.)
#
# 3. **bun** (buildBunPackage - preferred for npm packages)
#    - For npm packages when #1 and #2 don't apply
#    - Provides OFFLINE support (packages bundled in /nix/store)
#    - Use buildBunPackage with locked dependencies
#    - Benefits: Faster than npm, offline-first, deterministic builds
#
# 4. **npm** (buildNpmPackage - fallback if bun doesn't work)
#    - Use ONLY if buildBunPackage fails for technical reasons
#    - Still provides offline support via npmDepsHash
#    - Slower than bun but more compatible
#
# 5. **bunx/npx wrapper** (ABSOLUTE LAST RESORT)
#    - Online-only (downloads on every run)
#    - No offline support, no determinism
#    - Use ONLY as temporary solution until proper package is built
#    - MUST include TODO comment with migration plan
#
# ============================================================================
# CURRENT STATUS
# ============================================================================
#
# cclint: Using bunx wrapper (TODO: migrate to buildBunPackage)
# ccusage: Using bunx wrapper (TODO: migrate to buildBunPackage)
#
# NOTE: These are home-manager packages, not system packages.
# Imported in hosts/macbook-m4/home.nix via home.packages.

{ pkgs, ... }:

{
  # AI-specific development tools
  # Install via: home.packages = [ ... ] ++ (import ./ai-cli/ai-tools.nix { inherit pkgs; }).packages;
  packages = with pkgs; [
    # CLAUDE.md linter - validates AI context files
    # Source: https://github.com/felixgeelhaar/cclint
    # NPM: @felixgeelhaar/cclint
    # Uses npx wrapper (TODO: migrate to buildBunPackage for offline support)
    (writeShellScriptBin "cclint" ''
      exec ${bun}/bin/bunx --bun @felixgeelhaar/cclint "$@"
    '')

    # Claude Code usage analyzer
    # Source: https://github.com/ryoppippi/ccusage
    # NPM: ccusage
    # Uses bunx wrapper (bun is faster than npx)
    (writeShellScriptBin "ccusage" ''
      exec ${bun}/bin/bunx --bun ccusage@latest "$@"
    '')
  ];
}
