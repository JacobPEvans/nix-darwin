# GitHub Actions Workflows

CI/CD workflows for this nix-darwin configuration repository.

## Merge Gatekeeper Framework

### The Problem

GitHub branch protection only supports "always required" OR "not required" checks.
When path-filtered workflows don't run, the check stays "pending" forever, blocking merge and auto-merge.

### The Solution: CI Gate

The `ci-gate.yml` workflow implements the **Merge Gatekeeper Pattern**:

1. **Always triggers** on all PRs (no path filters at workflow level)
2. **Detects changes** using `dorny/paths-filter` to categorize modified files
3. **Conditional jobs** only run when their file category changed
4. **Skipped = Success** - GitHub treats skipped jobs as successful for dependencies
5. **Merge Gate** - Final job aggregates all results

### Branch Protection Setup

Set **only** `Merge Gate` as a required check in branch protection rules:

```text
Repository Settings → Rules → Rulesets → main
  → Require status checks to pass
  → Add: "Merge Gate"
```

### Adding New Checks

1. Add filter pattern under `changes.steps.filter.with.filters`:

   ```yaml
   filters: |
     your-check:
       - 'path/to/files/**'
       - '**.extension'
   ```

2. Add new job with conditional:

   ```yaml
   your-check:
     name: Your Check
     needs: changes
     if: needs.changes.outputs.your-check == 'true'
     runs-on: ubuntu-latest
     steps:
       # ... your check steps
   ```

3. Add job name to `gate.needs` array
4. Add job name to `gate.steps.check.with.allowed-skips`

## Active Workflows

### CI Gate (`ci-gate.yml`)

**The only required check.** Consolidates all conditional checks for PRs.

| Check | Triggers On | Runner |
|-------|-------------|--------|
| Nix Build | `**.nix`, `flake.lock`, `modules/**` | macOS |
| Nix Validate | `**.nix`, `flake.lock`, `modules/**` | Linux |
| Markdown Lint | `**.md`, `.markdownlint.*` | Linux |
| Claude Settings | `.claude/**`, `modules/home-manager/ai-cli/**` | Linux |
| File Size | `**.nix`, `**.md` | Linux |

### Claude Code Review (`review-code.yml`)

Automated PR review using [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action).

- **Triggers**: Pull requests (opened, synchronize)
- **Model**: Haiku (fast, cost-effective)
- **Skip**: Add `skip-claude` or `dependencies` label

**Setup**: Add `CLAUDE_CODE_OAUTH_TOKEN` to repository secrets.

### Standalone Workflows (Push to Main)

These run on pushes to `main` for visibility but are NOT required for PRs:

| Workflow | Purpose |
|----------|---------|
| `ci-nix.yml` | Nix build (standalone, mirrors gate) |
| `ci-validate.yml` | Nix flake check |
| `ci-markdownlint.yml` | Markdown lint (standalone) |
| `ci-validate-settings.yml` | Claude settings validation |
| `ci-file-length.yml` | File size enforcement |

### Dependency Updates (`deps-update-flake.yml`)

Automated flake.lock updates via scheduled workflow.

## Configuration

### Required Secrets

| Secret | Description | Required By |
|--------|-------------|-------------|
| `CLAUDE_CODE_OAUTH_TOKEN` | OAuth token for Claude Code GitHub App | `review-code.yml` |

### Permissions

Workflows use minimal required permissions:

- `contents: read` - Read repository code
- `pull-requests: read` - Detect changed files (paths-filter)
- `pull-requests: write` - Post review comments (Claude only)
- `id-token: write` - Determinate Systems authentication

## Auto-Merge Compatibility

With the Merge Gatekeeper pattern:

1. Enable auto-merge on PRs
2. `Merge Gate` always reports a status (pass/fail)
3. Skipped checks don't block merge
4. Failed checks correctly block merge
