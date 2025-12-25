# Dependency Monitoring System

Automated dependency monitoring and update system for nix-darwin configuration.

## Overview

This repository uses a **unified dependency update strategy** with a single workflow
handling all flake input updates:

| Trigger | What Updates | When |
|---------|--------------|------|
| **Schedule** (Tue/Fri) | ALL flake inputs | Noon UTC |
| **Schedule** (other days) | AI-focused inputs only | Noon UTC |
| **repository_dispatch** | ai-assistant-instructions only | Instant (on push) |
| **workflow_dispatch** | Configurable (manual trigger) | On demand |

## Unified Workflow

**Workflow**: `.github/workflows/deps-update-flake.yml`

A single workflow handles all flake input updates with verified commit signatures.

### Update Strategy

| Day | Inputs Updated |
|-----|----------------|
| Monday, Wednesday, Thursday, Saturday, Sunday | AI-focused inputs (9 total) |
| Tuesday, Friday | ALL flake inputs |
| repository_dispatch event | ai-assistant-instructions only (fast sync) |
| Manual with `update_all: true` | ALL flake inputs |

### AI-Focused Inputs (Daily)

Updated daily at noon UTC:

- `nixpkgs`
- `ai-assistant-instructions`
- `claude-code-plugins`
- `claude-cookbooks`
- `claude-plugins-official`
- `anthropic-skills`
- `claude-powerline`
- `superpowers-marketplace`
- `agent-os`

### Full Updates (Tue/Fri)

Includes all AI-focused inputs plus:

- `darwin`
- `home-manager`
- All other flake inputs

### Verified Commit Signatures

All commits are signed via GitHub's REST API using `peter-evans/create-pull-request`
with `sign-commits: true`. This produces verified signatures as `github-actions[bot]`.

**Key benefit**: No additional secrets required - uses built-in `GITHUB_TOKEN`.

### Manual Trigger

```bash
# Update based on day of week (AI-focused or all)
gh workflow run deps-update-flake.yml

# Force update ALL inputs regardless of day
gh workflow run deps-update-flake.yml -f update_all=true
```

## Instant Sync: ai-assistant-instructions

When the `ai-assistant-instructions` repository is updated, a `repository_dispatch`
event triggers an immediate sync of just that input.

### How It Works

1. Push to `ai-assistant-instructions` main branch triggers repository_dispatch
2. `deps-update-flake.yml` receives the `ai-instructions-updated` event
3. Only `ai-assistant-instructions` input is updated (fast sync)
4. PR created with verified signature

### Setup Required

See [Setup Cross-Repo Webhook](#setup-cross-repo-webhook) below.

## Package Version Monitoring

**Workflow**: `.github/workflows/deps-monitor-packages.yml`
**Script**: `scripts/workflows/check-package-versions.sh`

Monitors version changes for critical packages and creates a **single digest issue**.

**Monitored packages:**

- **Security-critical**: git, gnupg, gh, nodejs
- **AI Tools**: claude-code, claude-monitor, gemini-cli, ollama

**Schedule**: Monday 7 AM, Thursday 7 PM, Saturday 7 AM (UTC)

**Behavior**:

- Creates or updates a single issue labeled `package-updates`
- Auto-closes issue when all packages are current
- Adds `security` label if security-critical packages need updates

## AI-Powered Review

All dependency update PRs trigger the AI review workflow (`.github/workflows/review-deps.yml`):

1. **Analysis**: Claude Code analyzes flake.lock diff
2. **Risk Assessment**: Categorizes changes as LOW, MEDIUM, or HIGH risk
3. **Decision**:
   - LOW risk → Auto-merge enabled
   - MEDIUM/HIGH risk → Held for human review

**Risk levels:**

- **LOW**: Routine updates - nixpkgs bumps, patch updates, documentation repos
- **MEDIUM**: Minor version changes, new features, potential breaking changes
- **HIGH**: Major version changes, security updates, core infrastructure changes

## Setup Cross-Repo Webhook

To enable instant updates from ai-assistant-instructions:

### 1. Create GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with `repo` scope
3. Copy the token (you won't see it again)

### 2. Add Secret to ai-assistant-instructions

1. Go to ai-assistant-instructions repository
2. Settings → Secrets and variables → Actions
3. New repository secret:
   - Name: `NIX_CONFIG_DISPATCH_TOKEN`
   - Value: [paste your PAT]

### 3. Add Workflow to ai-assistant-instructions

Create `.github/workflows/trigger-nix-update.yml`:

```yaml
name: Trigger nix-config update

on:
  push:
    branches: [main]

jobs:
  dispatch:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger nix-config workflow
        run: |
          curl -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${{ secrets.NIX_CONFIG_DISPATCH_TOKEN }}" \
            https://api.github.com/repos/JacobPEvans/nix/dispatches \
            -d '{"event_type":"ai-instructions-updated","client_payload":{"ref":"${{ github.ref }}","sha":"${{ github.sha }}"}}'
```

### 4. Test the Webhook

1. Make a test commit to ai-assistant-instructions main branch
2. Check Actions tab in nix-config for triggered workflow
3. Verify PR is created with `dependencies` label

## Monitoring and Maintenance

### View Active Workflows

```bash
# Check scheduled workflows
gh workflow list

# View recent runs
gh run list --workflow=deps-update-flake.yml
gh run list --workflow=deps-monitor-packages.yml
```

### Package Version Report

Check the issue labeled `package-updates` for current package status:

```bash
gh issue list --label package-updates
```

## Troubleshooting

### Workflow not triggering

1. Check if workflow is enabled: Repository Settings → Actions → Enable workflows
2. Verify cron schedule is correct (use <https://crontab.guru>)
3. Check workflow runs: Actions tab → Select workflow → View runs

### Repository dispatch not working

1. Verify PAT token has `repo` scope
2. Confirm token is added as `NIX_CONFIG_DISPATCH_TOKEN` secret
3. Check sender workflow is committed to ai-assistant-instructions
4. Test with workflow_dispatch (manual trigger) first

### Package monitoring issue not updating

1. Verify `gh` CLI is available in workflow
2. Check for permission errors (needs `issues: write`)
3. Look for existing issues with `package-updates` label

### Commits showing as "Unverified"

This should not happen with the current setup. If it does:

1. Verify workflow uses `peter-evans/create-pull-request@v8`
2. Confirm `sign-commits: true` is set
3. Check that no custom token is overriding `GITHUB_TOKEN`

The workflow uses GitHub's REST API for commits, which automatically signs
them as `github-actions[bot]` with verified status.

## References

- [GitHub Actions Workflows](../.github/workflows/)
- [Nix Flake Inputs](../flake.nix)
- [AI Review Workflow](../.github/workflows/review-deps.yml)
- [Repository Dispatch Documentation](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#repository_dispatch)
