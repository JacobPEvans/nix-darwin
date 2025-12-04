# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Calendar Versioning](https://calver.org/).

## v0.8.0 - 2025-12-03

First formal release. This version consolidates all development work into a stable, documented release.

### Added

- **Flakes-Only nix-darwin Configuration**: Complete declarative system management for M4 Max MacBook Pro
  - Determinate Nix integration (daemon, updates, core config)
  - nix-darwin for macOS packages and system settings
  - home-manager for user environment (shell, git, dotfiles)
  - mac-app-util for stable TCC permissions across rebuilds

- **Multi-Host Architecture**: Extensible structure supporting multiple machines
  - `hosts/macbook-m4/` - Active M4 Max MacBook Pro (nix-darwin + home-manager)
  - `hosts/ubuntu-server/` - Template for Ubuntu server (home-manager standalone)
  - `hosts/proxmox/` - Template for Proxmox server (home-manager standalone)
  - `hosts/windows-workstation/` - Placeholder for future Windows Nix support

- **Comprehensive Package Management**:
  - Modern CLI tools: bat, delta, eza, fd, fzf, htop, jq, ncdu, ripgrep, tldr, tree
  - Development: nodejs, gh, claude-code, gemini-cli
  - GUI apps: VS Code, Obsidian, Raycast, Bitwarden, Zoom
  - Cloud/security: awscli2, aws-vault, bitwarden-cli
  - Linters: shellcheck, shfmt, markdownlint-cli2, actionlint, nixfmt-classic

- **macOS System Configuration**:
  - Dock: 64px icons, hot corners, fixed space ordering, no recent apps
  - Finder: Show hidden files, list view, full POSIX path, folders first
  - Keyboard: Fast key repeat, full keyboard access
  - Trackpad: Tap-to-click, two-finger right-click, natural scrolling
  - System UI: Dark mode, expanded panels, battery %, control center items

- **AI CLI Permission Management**: Three-tier security model
  - 280+ auto-approved commands across 25 categories
  - 32 commands requiring user confirmation (potentially dangerous but legitimate)
  - 40+ permanently blocked catastrophic operations
  - Supports Claude Code, Gemini CLI, and GitHub Copilot

- **Anthropic Claude Code Ecosystem**:
  - 12 official plugins from 2 marketplaces (claude-code + claude-plugins-official)
  - 6 cookbook commands + 1 agent from claude-cookbooks
  - Skills framework from anthropics/skills
  - Agent OS integration for spec-driven development
  - SDK development shells (Python and TypeScript)

- **Development Shells**: Project-specific environments via `nix develop`
  - `python` - Python with pip, venv
  - `python-data` - Data science: pandas, numpy, scipy, matplotlib, jupyter
  - `js` - Node.js with npm, yarn, pnpm, TypeScript
  - `go` - Go with gopls, delve debugger
  - `terraform` - Terraform/OpenTofu
  - `claude-sdk-python` - Anthropic SDK for Python
  - `claude-sdk-typescript` - Anthropic SDK for TypeScript

- **Shell Configuration**:
  - Oh My Zsh with plugins: git, docker, macos, z, colored-man-pages
  - Autosuggestions, syntax highlighting, 100k history
  - Custom aliases and functions (gitmd, d-r, ll, etc.)
  - GPG shell integration for commit signing

- **Git Configuration**:
  - GPG signing enabled by default
  - 20+ common aliases (st, lo, lg, co, etc.)
  - Security: fsck checks, fetch pruning, rebase on pull
  - delta as diff viewer

### Infrastructure

- **GitHub Actions**:
  - `claude.yml` - Automated PR review using Claude Code
  - `nix-ci.yml` - Nix flake validation with Determinate Systems actions
  - `markdownlint.yml` - Markdown linting

- **Linting & Validation**:
  - markdownlint-cli2 with project-specific configuration
  - Pre-commit integration via direnv
  - Automated flake checks

- **External Integrations**:
  - ai-assistant-instructions for centralized AI agent config
  - agent-os for spec-driven development workflows
  - mac-app-util workaround for gitlab.common-lisp.net Anubis protection

### Documentation

- **Core Documentation**:
  - README.md - Project overview and quick start
  - ARCHITECTURE.md - Detailed structure and module relationships
  - RUNBOOK.md - Step-by-step operational procedures
  - TROUBLESHOOTING.md - Common issues and solutions
  - SETUP.md - Initial setup and configuration decisions

- **AI & Integration Docs**:
  - CLAUDE.md - AI agent instructions (scope, permissions, workflow)
  - docs/ANTHROPIC-ECOSYSTEM.md - 500+ line Claude Code integration reference

- **Standard Open-Source Files**:
  - CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md
  - Apache 2.0 LICENSE

---

*This changelog consolidates all development work from initial creation through December 3, 2025.*
