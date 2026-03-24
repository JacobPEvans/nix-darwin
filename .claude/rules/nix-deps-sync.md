# Nix Dependencies Synchronization

## Rule: Always Keep nix-darwin in Sync with Latest JacobPEvans/nix-* Repos

**Scope**: All flake inputs from `github:JacobPEvans/nix-*`

**Current inputs** (as of 2026-03-24):
- `nix-ai` — AI CLI ecosystem (Claude, Gemini, Copilot, MCP)
- `nix-home` — Cross-platform home-manager modules (git, zsh, vscode, monitoring)

**Private repos** (explicitly excluded from sync rule):
- Any repositories marked as private in GitHub are completely ignored
- Private repos are not referenced in this rule or any sync processes

## Enforcement

### Automated (CI)

- Daily flake update via GitHub Actions (`.github/workflows/deps-update-flake.yml`)
- Updates all flake inputs automatically
- Renovate bot assists with dependency PRs

### Manual (Development)

**When to update**:
- After shipping new releases in nix-ai or nix-home
- When reviewing upstream changes that affect nix-darwin configuration
- As part of regular maintenance cycles (bi-weekly minimum)

**How to update**:

```bash
/flake-rebuild
```

This command:
1. Syncs main branch
2. Creates feature branch `chore/flake-update-YYYY-MM-DD`
3. Runs `nix flake update` to fetch latest inputs from all JacobPEvans/nix-* repos
4. Runs quality checks (fmt, statix, deadnix, flake check)
5. Rebuilds system to validate all changes
6. Creates PR with auto-merge enabled

## Rationale

**Why**: nix-ai and nix-home contain critical security patches, bug fixes, and new features
that affect system stability and configuration management. Staying current ensures the
system benefits from the latest improvements across the entire nix-* ecosystem.

**Why auto-merge**: Dependency updates are non-breaking by design. The flake.lock is
a lock file; semantic versioning is enforced by release-please. If an update breaks
the build, the CI gate catches it before merge.

## Related Files

- `.github/workflows/deps-update-flake.yml` — Daily automated update
- `flake.nix` — Input declarations
- `flake.lock` — Current pinned versions (auto-updated)
- `/flake-rebuild` command — Manual update trigger
