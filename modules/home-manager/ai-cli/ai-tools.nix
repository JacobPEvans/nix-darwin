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
#    - Example: claude-code, claude-monitor, gemini-cli
#
# 2. **homebrew** (ONLY if not in nixpkgs)
#    - Fallback for packages missing from nixpkgs
#    - Check: brew search <package>
#    - Add to modules/darwin/homebrew.nix with clear justification
#    - Document WHY homebrew is needed (not in nixpkgs, severely outdated, etc.)
#
# 3. **bunx wrapper** (for npm packages not in nixpkgs or homebrew)
#    - Standard solution for npm/bun packages
#    - Always pin to specific version: package@x.y.z
#    - Downloads on first run, cached locally by bun
#    - Benefits: Simple, minimal code, easy version updates
#    - Pattern: writeShellScriptBin with bunx --bun
#
# 4. **pipx** (for Python packages not in nixpkgs)
#    - Standard solution for Python CLI tools
#    - Installed separately via: pipx install <package>
#    - Benefits: Isolated environments, easy updates
#
# ============================================================================
# CURRENT STATUS
# ============================================================================
#
# NIXPKGS PACKAGES:
#   gemini-cli, github-mcp-server, terraform-mcp-server
#
# BUNX WRAPPER PACKAGES (npm packages not in nixpkgs/homebrew):
#   cclint: @felixgeelhaar/cclint@0.12.1
#   gh-copilot: @githubnext/github-copilot-cli@latest (unversioned - upstream)
#   chatgpt: chatgpt-cli@3.3.0
#   claude-flow: claude-flow@2.0.0
#
# HOMEBREW PACKAGES (from modules/darwin/homebrew.nix):
#   block-goose-cli: Block's AI agent (nixpkgs outdated at time of addition)
#
# PIPX PACKAGES (Python, installed separately):
#   aider: aider-chat (AI pair programming)
#
# NOTE: These are home-manager packages, not system packages.
# Imported in hosts/macbook-m4/home.nix via home.packages.

{ pkgs, ... }:

{
  # AI-specific development tools
  # Install via: home.packages = [ ... ] ++ (import ./ai-cli/ai-tools.nix { inherit pkgs; }).packages;
  #
  # See CURRENT STATUS section at the top of this file for package details.
  packages = with pkgs; [
    # ==========================================================================
    # Claude Code Ecosystem
    # ==========================================================================

    # CLAUDE.md linter - validates AI context files
    # Source: https://github.com/felixgeelhaar/cclint
    # NPM: @felixgeelhaar/cclint (pinned version)
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
    # OpenAI Codex CLI
    # ==========================================================================
    # Lightweight coding agent that runs in your terminal
    # Available in nixpkgs (0.92.0)
    codex

    # ==========================================================================
    # GitHub Copilot CLI
    # ==========================================================================
    # Source: https://github.com/github/gh-copilot
    # NPM: @githubnext/github-copilot-cli (using @latest - no stable versioning)
    (writeShellScriptBin "gh-copilot" ''
      exec ${bun}/bin/bunx --bun @githubnext/github-copilot-cli@latest "$@"
    '')

    # ==========================================================================
    # OpenAI ChatGPT CLI
    # ==========================================================================
    # Source: https://github.com/manno/chatgpt-cli
    # NPM: chatgpt-cli (pinned version)
    (writeShellScriptBin "chatgpt" ''
      exec ${bun}/bin/bunx --bun chatgpt-cli@3.3.0 "$@"
    '')

    # ==========================================================================
    # Claude Flow - AI Agent Orchestration Platform
    # ==========================================================================
    # Source: https://github.com/ruvnet/claude-flow
    # NPM: claude-flow (pinned version)
    (writeShellScriptBin "claude-flow" ''
      exec ${bun}/bin/bunx --bun claude-flow@2.7.47 "$@"
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
