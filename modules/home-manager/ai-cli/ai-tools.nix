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
# Claude Code Ecosystem:
#   cclint: Using bunx wrapper (TODO: migrate to buildBunPackage)
#   ccusage: Using bunx wrapper (TODO: migrate to buildBunPackage)
#
# Google Gemini:
#   gemini: Using bunx wrapper (nixpkgs 0.22.5 has stale npm cache)
#
# GitHub Copilot:
#   github-copilot-cli: Using bunx wrapper (nixpkgs 0.0.373 has broken package-lock.json)
#
# OpenAI:
#   chatgpt: Using bunx wrapper (not available in nixpkgs)
#
# Block Goose:
#   goose: Using bunx wrapper (nixpkgs depends on broken python3.13-twisted)
#
# Charmbracelet:
#   crush: Using bunx wrapper (nixpkgs depends on broken python3.13-twisted)
#
# Aider:
#   aider: Via pipx (Python package, not available in nixpkgs)
#
# NOTE: These are home-manager packages, not system packages.
# Imported in hosts/macbook-m4/home.nix via home.packages.

{ pkgs, ... }:

{
  # AI-specific development tools
  # Install via: home.packages = [ ... ] ++ (import ./ai-cli/ai-tools.nix { inherit pkgs; }).packages;
  packages = with pkgs; [
    # ==========================================================================
    # Claude Code Ecosystem
    # ==========================================================================

    # CLAUDE.md linter - validates AI context files
    # Source: https://github.com/felixgeelhaar/cclint
    # NPM: @felixgeelhaar/cclint
    # SECURITY: Uses bunx wrapper with pinned version; not yet packaged in nixpkgs.
    # TODO: Migrate to buildBunPackage for offline/reproducible builds.
    (writeShellScriptBin "cclint" ''
      exec ${bun}/bin/bunx --bun @felixgeelhaar/cclint@0.12.1 "$@"
    '')

    # Claude Code usage analyzer
    # Source: https://github.com/ryoppippi/ccusage
    # NPM: ccusage
    # SECURITY: Uses bunx wrapper with pinned version; not yet packaged in nixpkgs.
    (writeShellScriptBin "ccusage" ''
      exec ${bun}/bin/bunx --bun ccusage@0.6.2 "$@"
    '')

    # ==========================================================================
    # Google Gemini CLI
    # ==========================================================================
    # Nixpkgs version 0.22.5 has stale npm dependency cache
    # npm ci fails: "ENOTCACHED - request to registry.npmjs.org/string-width failed"
    # Using bunx wrapper until nixpkgs updates to fixed version
    # Source: https://github.com/google-gemini/gemini-cli
    # NPM: @google/gemini-cli
    (writeShellScriptBin "gemini" ''
      exec ${bun}/bin/bunx --bun @google/generative-ai-cli@latest "$@"
    '')

    # ==========================================================================
    # GitHub Copilot CLI
    # ==========================================================================
    # Nixpkgs version 0.0.373 has broken package-lock.json
    # npm ci fails: "Missing: @github/copilot-darwin-arm64@ from lock file"
    # Using bunx wrapper until nixpkgs updates to fixed version
    # Source: https://github.com/github/gh-copilot
    # NPM: @githubnext/github-copilot-cli
    (writeShellScriptBin "github-copilot-cli" ''
      exec ${bun}/bin/bunx --bun @githubnext/github-copilot-cli "$@"
    '')

    # ==========================================================================
    # OpenAI ChatGPT CLI
    # ==========================================================================
    # Not available in nixpkgs - using bunx wrapper
    # Source: https://github.com/manno/chatgpt-cli
    # NPM: chatgpt-cli
    (writeShellScriptBin "chatgpt" ''
      exec ${bun}/bin/bunx --bun chatgpt-cli "$@"
    '')

    # ==========================================================================
    # Block Goose CLI
    # ==========================================================================
    # Nixpkgs version depends on python3.13-twisted with test failures
    # (IPv6 TCP tests timeout after 120s)
    # Using bunx wrapper until upstream twisted package is fixed
    # Source: https://github.com/block/goose
    # NPM: goose-ai
    (writeShellScriptBin "goose" ''
      exec ${bun}/bin/bunx --bun goose-ai "$@"
    '')

    # ==========================================================================
    # Charmbracelet Crush (successor to OpenCode)
    # ==========================================================================
    # Nixpkgs version depends on python3.13-twisted with test failures
    # Using bunx wrapper until upstream twisted package is fixed
    # Source: https://github.com/charmbracelet/crush
    # NPM: @charmbracelet/crush
    (writeShellScriptBin "crush" ''
      exec ${bun}/bin/bunx --bun @charmbracelet/crush "$@"
    '')

    # ==========================================================================
    # Aider - AI pair programming in the terminal
    # ==========================================================================
    # Not available in nixpkgs - python package, use pip/pipx
    # Source: https://github.com/paul-gauthier/aider
    # PyPI: aider-chat
    # Note: Using python3.withPackages pipx from common/packages.nix
    # Install: pipx install aider-chat
    # This creates a marker comment so users know aider is via pipx
  ];
}
