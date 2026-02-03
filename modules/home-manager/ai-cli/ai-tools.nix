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
# DIRECT NIXPKGS PACKAGES (from pkgs):
#   gemini-cli: 0.22.5 (via nixpkgs)
#
# BUNX WRAPPER PACKAGES (online-only, should migrate to buildBunPackage):
#   cclint: @felixgeelhaar/cclint@0.12.1
#     - Status: TODO - migrate to buildBunPackage
#   gh-copilot: @githubnext/github-copilot-cli@latest
#     - Status: Waiting - nixpkgs 0.0.373 has broken package-lock
#   chatgpt: chatgpt-cli@3.3.0
#     - Status: Not in nixpkgs
#   claude-flow: claude-flow@2.0.0
#     - Status: Not in nixpkgs or homebrew - npm package for AI agent orchestration
#
# HOMEBREW PACKAGES (from modules/darwin/homebrew.nix):
#   block-goose-cli: Block's AI agent
#     - Status: Using homebrew - nixpkgs was >30 days old at time of addition; homebrew actively maintained
#
# OTHER TOOLS (installed via other methods):
#   aider: Via pipx (Python package, not available in nixpkgs)
#
# NOTE: These are home-manager packages, not system packages.
# Imported in hosts/macbook-m4/home.nix via home.packages.

{ pkgs, ... }:

{
  # AI-specific development tools
  # Install via: home.packages = [ ... ] ++ (import ./ai-cli/ai-tools.nix { inherit pkgs; }).packages;
  #
  # PACKAGING STRATEGY:
  # - Direct nixpkgs packages: gemini-cli (available in nixpkgs)
  # - Bunx wrappers: cclint, gh-copilot, chatgpt (not in nixpkgs or nixpkgs broken)
  # - Python tools: aider via pipx (not available in nixpkgs)
  #
  # See CURRENT STATUS section at the top of this file for package details.
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
    # MCP Servers (Model Context Protocol)
    # ==========================================================================
    # Used with Claude Code via `claude mcp add --scope user --transport stdio`
    # Configured in ~/.claude.json (user scope)

    # GitHub MCP Server - GitHub API integration
    # Source: https://github.com/github/github-mcp-server
    # Requires: GITHUB_PERSONAL_ACCESS_TOKEN env var
    github-mcp-server

    # Terraform MCP Server - Terraform/OpenTofu integration
    # Source: https://github.com/hashicorp/terraform-mcp-server
    terraform-mcp-server

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
    # Claude Flow - AI Agent Orchestration Platform
    # ==========================================================================
    # Source: https://github.com/ruvnet/claude-flow
    # NPM: claude-flow
    # SECURITY: Uses bunx wrapper with pinned version; not in nixpkgs or homebrew
    # TODO: Migrate to buildBunPackage for offline/reproducible builds
    (writeShellScriptBin "claude-flow" ''
      exec ${bun}/bin/bunx --bun claude-flow@2.0.0 "$@"
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
