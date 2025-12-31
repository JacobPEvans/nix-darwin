# Common Packages
#
# Universal packages that should be installed on ALL systems (macOS, Linux, etc.)
# These are system-level tools, not user-specific.
#
# Usage:
#   - Darwin: imported in darwin/common.nix → environment.systemPackages
#   - Linux:  imported in linux/common.nix → home.packages (home-manager standalone)
#
# NOTE: This file returns a function that takes pkgs and returns a list of packages.

{ pkgs }:

with pkgs;
[
  # ==========================================================================
  # Git & Pre-commit Hooks
  # ==========================================================================
  # Framework for managing git pre-commit hooks - essential for code quality
  pre-commit

  # ==========================================================================
  # Universal Linters
  # ==========================================================================
  # These are the most common linters used across projects. They support
  # pre-commit hooks and should be available on any development machine.

  # Shell
  shellcheck # Shell script static analysis (POSIX, bash)
  shfmt # Shell script formatter

  # Documentation
  lychee # Link checker for markdown and HTML (validates URLs in docs)
  markdownlint-cli2 # Markdown linter (README, docs exist everywhere)

  # CI/CD
  actionlint # GitHub Actions workflow linter

  # Nix (2025 official tooling)
  nixfmt-rfc-style # Official Nix formatter (RFC 166, v1.1.0+)
  statix # Nix linter - catches anti-patterns
  deadnix # Find unused code in .nix files
  treefmt # Multi-language formatter runner
  nix-tree # Browse Nix store dependencies interactively

  # JSON
  check-jsonschema # JSON Schema validator CLI (for settings validation)

  # ==========================================================================
  # Security & Credential Management
  # ==========================================================================
  # Password management and secure credential storage for all environments.

  bitwarden-cli # CLI for Bitwarden password manager (bw command)
  bws # Bitwarden Secrets Manager CLI (for machine secrets)
  doppler # Doppler secrets manager CLI (for CI/CD and team secrets)

  # ==========================================================================
  # Cloud Infrastructure (AWS)
  # ==========================================================================
  # AWS tooling for infrastructure management and secure credential handling.

  awscli2 # AWS CLI v2 - unified tool to manage AWS services
  aws-vault # Secure AWS credential storage (uses OS keychain)

  # ==========================================================================
  # HTTP & API Tools
  # ==========================================================================
  # Tools for testing and working with HTTP APIs and web services.

  rapidapi # Full-featured HTTP client for testing and describing APIs

  # ==========================================================================
  # Python Tools
  # ==========================================================================
  # Fast Python package installer and management tools.
  uv # Extremely fast Python package installer and resolver

  # ==========================================================================
  # Python Environment
  # ==========================================================================
  # Create a unified Python environment with all required packages.
  # This ensures all modules can be imported in the same interpreter.
  # Using python3.withPackages instead of individual python3Packages.*
  (python3.withPackages (ps: [
    ps.grip # Preview GitHub Markdown files locally
    ps.langchain-ollama # LangChain integration for Ollama
    ps.ollama # Ollama Python library for local LLM interaction
    ps.pipx # Install and run Python CLI apps in isolated environments
    ps.pygithub # GitHub API v3 Python library
  ]))
]
