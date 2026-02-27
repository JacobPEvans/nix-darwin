# Nix Configuration - AI Agent Instructions

## Repository Purpose

macOS system configuration managed with nix-darwin and Nix flakes (Determinate Nix).
Orchestrates system packages, networking, security, and home-manager via two companion repos (nix-ai, nix-home).

## Critical Constraints

1. **Flakes-only**: Never use `nix-env`, `nix-channels`, or imperative commands
2. **Determinate Nix**: Keep `nix.enable = false` in darwin config; use `nix` (Determinate), not `nix-env` or `nix-channel`
3. **Nixpkgs first**: Use homebrew only when nixpkgs unavailable; prefer `pkgs.*` over overlays or custom derivations
4. **Worktrees required**: Run `/init-worktree` before any work
5. **No direct main commits**: Always use feature branches via PRs

## Build & Validate

Build validation is enforced by **GitHub Actions CI** (`ci-gate.yml`) on every PR — not by a local pre-push hook.

Local quick checks (formatting, linting, dead code) run automatically on every commit via pre-commit hooks:

```bash
nix flake check         # full flake check (run in CI)
nix fmt                 # format all Nix files (alejandra)
statix check            # static analysis
deadnix                 # dead code detection
```

A full `nix flake check && sudo darwin-rebuild switch --flake .` is run by CI on macOS runners and must
pass before merge. You may run it locally to verify before pushing, but it is not required locally.

## File Conventions

- `.nix` files: Nix expression language only
- Modules follow `{ config, pkgs, lib, ... }:` function pattern
- Use `lib.mkOption` for configurable options
- Attribute sets use `{}` not record syntax

## Common Patterns

```nix
# Module definition
{ config, pkgs, lib, ... }: {
  options.my.option = lib.mkEnableOption "description";
  config = lib.mkIf config.my.option { ... };
}
```

## Worktree Workflow

```bash
cd ~/git/nix-darwin
git fetch origin
git worktree add <branch> -b <branch> origin/main
cd <branch>
```

## File References

- **Rules**: `agentsmd/rules/` (worktrees, version-validation, skill-namespace-resolution, security-alert-triage)
- **Security**: See SECURITY.md and `agentsmd/rules/security-alert-triage.md` for alert policies
- **Inventory**: `MANIFEST.md` — update when adding/removing packages

## Part of a Trio

| Repo | Purpose |
| ---- | ------- |
| **nix-darwin** (this repo) | macOS system config |
| [nix-ai](https://github.com/JacobPEvans/nix-ai) | AI coding tools (Claude, Gemini, Copilot, MCP) |
| [nix-home](https://github.com/JacobPEvans/nix-home) | Dev environment (git, zsh, VS Code, tmux) |

## PR Rules

- Never auto-merge without explicit user approval
- 50-comment limit per PR
- Batch commits locally, push once

## Secrets

Secrets managed via Bitwarden Secrets Manager — never hardcode credentials or tokens.
