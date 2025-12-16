# Dependency Monitoring System

Multi-tier automated dependency monitoring and update system for nix-darwin configuration.

## Overview

This repository uses a sophisticated **4-tier dependency monitoring strategy** to keep Nix
flake inputs and packages current while minimizing noise and maximizing safety:

| Tier | What | Schedule | Trigger | Workflow | PR Label |
|------|------|----------|---------|----------|----------|
| **Instant** | ai-assistant-instructions | On push to main | repository_dispatch | deps-update-ai-instructions.yml | `ai-instructions` |
| **Daily** | Anthropic repos (4 inputs) | 6 AM UTC daily | Scheduled | deps-update-anthropic.yml | `anthropic` |
| **Bi-weekly** | All flake inputs (11 total) | Mon/Thu 6 AM UTC | Scheduled | deps-update-flake.yml | `dependencies` |
| **Tri-weekly** | Package versions (8 packages) | Mon 7am, Thu 7pm, Sat 7am | Scheduled | deps-monitor-packages.yml | `package-updates` |

## Workflows

### 1. Instant Updates: ai-assistant-instructions

**Workflow**: `.github/workflows/deps-update-ai-instructions.yml`

Immediately syncs permission configurations and AI instructions when the ai-assistant-instructions repository is updated.

**How it works:**

1. Push to `ai-assistant-instructions` main branch triggers repository_dispatch
2. This repo receives the event and updates the `ai-assistant-instructions` input
3. Creates PR with `ai-instructions` label
4. AI review workflow analyzes changes
5. Low-risk permission updates typically auto-merge

**Setup required:**
See [Setup Instructions](#setup-cross-repo-webhook) below.

### 2. Daily Fast-Track: Anthropic Repositories

**Workflow**: `.github/workflows/deps-update-anthropic.yml`

Updates fast-moving Anthropic repositories daily to stay current with Claude Code ecosystem.

**Updated inputs:**

- `claude-code-plugins` (anthropics/claude-code)
- `claude-cookbooks` (anthropics/claude-cookbooks)
- `claude-plugins-official` (anthropics/claude-plugins-official)
- `anthropic-skills` (anthropics/skills)

**Schedule**: Daily at 6 AM UTC

**Manual trigger:**

```bash
gh workflow run deps-update-anthropic.yml
```

### 3. Bi-Weekly Full Update: All Inputs

**Workflow**: `.github/workflows/deps-update-flake.yml`

Comprehensive update of all 11 flake inputs including nixpkgs, darwin, home-manager, and other dependencies.

**Schedule**: Monday and Thursday at 6 AM UTC

**Manual trigger:**

```bash
gh workflow run deps-update-flake.yml
```

### 4. Tri-Weekly Package Monitoring

**Workflow**: `.github/workflows/deps-monitor-packages.yml`
**Script**: `scripts/workflows/check-package-versions.sh`

Monitors version changes for critical packages and creates a **single digest issue** with findings.

**Monitored packages:**

- **Security-critical**: git, gnupg, gh, nodejs
- **AI Tools**: claude-code, claude-monitor, gemini-cli, ollama

**Schedule**:

- Monday 7 AM UTC (after full flake update)
- Thursday 7 PM UTC (after full flake update)
- Saturday 7 AM UTC (mid-week check)

**Behavior**:

- Creates or updates a single issue labeled `package-updates`
- Auto-closes issue when all packages are current
- Adds `security` label if security-critical packages need updates

**Manual trigger:**

```bash
gh workflow run deps-monitor-packages.yml
```

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

Copy the template from `docs/ai-instructions-trigger-workflow.yml` to:

```text
ai-assistant-instructions/.github/workflows/trigger-nix-update.yml
```

Or use this command (from ai-assistant-instructions repo):

```bash
mkdir -p .github/workflows
curl -o .github/workflows/trigger-nix-update.yml \
  https://raw.githubusercontent.com/JacobPEvans/nix-config/main/docs/ai-instructions-trigger-workflow.yml
```

### 4. Test the Webhook

1. Make a test commit to ai-assistant-instructions main branch
2. Check Actions tab in nix-config for triggered workflow
3. Verify PR is created with `ai-instructions` label

## Monitoring and Maintenance

### View Active Workflows

```bash
# Check scheduled workflows
gh workflow list

# View recent runs
gh run list --workflow=deps-update-flake.yml
gh run list --workflow=deps-update-anthropic.yml
gh run list --workflow=deps-monitor-packages.yml
```

### Package Version Report

Check the issue labeled `package-updates` for current package status:

```bash
gh issue list --label package-updates
```

### Adjust Schedules

Edit workflow files to change update frequencies:

```yaml
# .github/workflows/deps-update-anthropic.yml
schedule:
  - cron: "0 6 * * *" # Daily at 6 AM UTC
```

**Cron syntax:**

- `0 6 * * 1` = Monday 6 AM UTC
- `0 6 * * *` = Every day 6 AM UTC
- `0 */6 * * *` = Every 6 hours

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

### No PR created despite changes

1. Check if branch already exists: `git branch -r | grep deps/`
2. Delete stale branch: `git push origin --delete deps/anthropic-daily`
3. Re-run workflow

## Migration from Manual Updates

If migrating from manual `nix flake update`:

1. ✅ These workflows replace manual updates
2. ✅ Existing bi-weekly schedule remains unchanged
3. ✅ New: Daily Anthropic updates (more current tooling)
4. ✅ New: Instant ai-instructions sync (immediate permission updates)
5. ✅ New: Package version visibility (proactive monitoring)

**No breaking changes** - the bi-weekly full update (deps-update-flake.yml) continues as before.

## Future Enhancements

Potential improvements to consider:

- [ ] Add agent-os to daily fast-track (currently only in bi-weekly)
- [ ] Create security-specific workflow for CVE scanning
- [ ] Add Slack/Discord notifications for HIGH risk updates
- [ ] Expand package monitoring to more packages
- [ ] Add performance metrics (build time tracking)

## References

- [GitHub Actions Workflows](.github/workflows/)
- [Nix Flake Inputs](../flake.nix)
- [AI Review Workflow](../.github/workflows/review-deps.yml)
- [Repository Dispatch Documentation](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#repository_dispatch)
