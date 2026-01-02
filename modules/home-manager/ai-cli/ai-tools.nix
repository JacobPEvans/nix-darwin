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
# Bunx wrappers in this file:
#   cclint: @felixgeelhaar/cclint@0.12.1 (TODO: migrate to buildBunPackage)
#   gh-copilot: @githubnext/github-copilot-cli@latest (nixpkgs broken)
#   chatgpt: chatgpt-cli@3.3.0 (not in nixpkgs)
#   crush: @charmbracelet/crush@0.1.1 (nixpkgs broken dependency)
#
# Nixpkgs packages in this file:
#   gemini-cli: 0.22.5
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
  #
  # NOTE: Only claude-code and claude-monitor come from nixpkgs (via darwin/common.nix).
  # Other packages below are provided as bunx wrappers due to nixpkgs build issues.
  # See CURRENT STATUS section at the top of this file for details.
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

    # ==========================================================================
    # Google Gemini CLI
    # ==========================================================================
    # Available in nixpkgs (0.22.5)
    # Source: https://github.com/google-gemini/gemini-cli
    gemini-cli

    # ==========================================================================
    # GitHub Copilot CLI
    # ==========================================================================
    # Source: https://github.com/github/gh-copilot
    # NPM: @githubnext/github-copilot-cli
    # SECURITY: Uses bunx wrapper (unversioned); nixpkgs 0.0.373 has broken package-lock
    # TODO: Pin version and migrate to buildBunPackage once nixpkgs is fixed
    (writeShellScriptBin "gh-copilot" ''
      exec ${bun}/bin/bunx --bun @githubnext/github-copilot-cli@latest "$@"
    '')

    # ==========================================================================
    # OpenAI ChatGPT CLI
    # ==========================================================================
    # Source: https://github.com/manno/chatgpt-cli
    # NPM: chatgpt-cli
    # SECURITY: Uses bunx wrapper with pinned version; not available in nixpkgs
    (writeShellScriptBin "chatgpt" ''
      exec ${bun}/bin/bunx --bun chatgpt-cli@3.3.0 "$@"
    '')

    # ==========================================================================
    # Charmbracelet Crush (successor to OpenCode)
    # ==========================================================================
    # Source: https://github.com/charmbracelet/crush
    # NPM: @charmbracelet/crush
    # SECURITY: Uses bunx wrapper with pinned version; nixpkgs depends on broken twisted
    (writeShellScriptBin "crush" ''
      exec ${bun}/bin/bunx --bun @charmbracelet/crush@0.1.1 "$@"
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
