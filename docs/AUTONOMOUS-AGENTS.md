# Autonomous AI Agents

This document describes the "set and forget" AI agents that run 24/7/365,
monitor GitHub, and handle issues/PRs automatically with minimal interaction.

## Overview

| Agent | Type | Automation Level | Primary Use Case |
|-------|------|------------------|------------------|
| **OpenHands** | GitHub Action | Issue → PR | Implements features/fixes from issues |
| **Ellipsis** | GitHub App | PR Review | Auto-reviews code, fixes bugs |
| **GitHub Copilot Agent** | GitHub Native | Issue → PR | Delegates issues to AI |

## OpenHands (Headless Mode)

**Repository**: [All-Hands-AI/OpenHands](https://github.com/All-Hands-AI/OpenHands)

OpenHands is an open-source AI agent that runs in headless mode via GitHub Actions.

### OpenHands Workflow

1. You create a GitHub issue describing a task
2. You add the `ai:openhands` label to the issue
3. OpenHands spins up a Docker container
4. It reads the issue, analyzes the codebase
5. Implements changes and creates a PR
6. Comments on the issue with the result

### Configuration

The workflow is defined in `.github/workflows/ai-openhands.yml`.

**Required Secrets:**

- `ANTHROPIC_API_KEY` - Your Anthropic API key

**Trigger:**

- Add the `ai:openhands` label to any issue

### Usage Example

```markdown
# Issue Title: Add dark mode support

## Description
Add a dark mode toggle to the application settings.

## Acceptance Criteria
- [ ] Toggle switch in settings
- [ ] Persist preference
- [ ] Apply theme without refresh
```

Then add the `ai:openhands` label → OpenHands creates a PR.

### Self-Hosting (OrbStack/Proxmox)

For running OpenHands on your own infrastructure:

```bash
# Run OpenHands in Docker
docker run -it --rm \
  -e ANTHROPIC_API_KEY=your-key \
  -v /path/to/repo:/workspace \
  docker.all-hands.dev/all-hands-ai/openhands:latest

# Headless mode
docker run --rm \
  -e ANTHROPIC_API_KEY=your-key \
  -v /path/to/repo:/workspace \
  docker.all-hands.dev/all-hands-ai/openhands:latest \
  python -m openhands.core.main -t "your task here"
```

## Ellipsis (Code Review)

**Website**: [ellipsis.dev](https://www.ellipsis.dev/)

Ellipsis is an AI-powered code review assistant (YC W24).

### Ellipsis Features

- **Automatic PR Review**: Reviews every commit on every PR
- **Bug Detection**: Flags logical mistakes, style violations, anti-patterns
- **AI Bug Fixes**: Tag `@ellipsis-dev` to get fixes
- **Style Guide Enforcement**: Write rules in natural language
- **20+ Languages**: Python, JavaScript, Java, TypeScript, Go, etc.

### Ellipsis Workflow

1. Install the Ellipsis GitHub App (2-click install)
2. Ellipsis automatically reviews all PRs
3. Tag `@ellipsis-dev` in comments to request fixes
4. Ellipsis pushes commits to fix issues

### Installation

**This requires human setup:**

1. Go to [ellipsis.dev](https://www.ellipsis.dev/)
2. Click "Install" or "Get Started"
3. Authorize the GitHub App for your repositories
4. Configure via `ellipsis.yaml` in your repo root (optional)

### Configuration (Optional)

Create `ellipsis.yaml` in your repository root:

```yaml
# Ellipsis configuration
version: 1.0

# Custom style guide rules
rules:
  - "All Nix files must use nixfmt-rfc-style formatting"
  - "Prefer declarative configuration over imperative scripts"
  - "Comments should explain 'why', not 'what'"
  - "Each module should be under 200 lines"

# Files to ignore
ignore:
  - "*.lock"
  - "result"
  - ".direnv/"

# Review settings
review:
  auto_approve: false
  require_tests: true
```

### Pricing

- **Free**: Public repositories
- **Paid**: Private repositories (team plans)

## GitHub Copilot Coding Agent

**Built into GitHub** - Works with Copilot subscription.

### Copilot Features

- Assigns issues to AI agent
- Works in GitHub Actions environment
- Reads issues, edits code, runs tests
- Opens pull requests for review

### Availability

This is rolling out as part of GitHub Copilot. Check your
GitHub settings → Copilot → Features for availability.

## Comparison Matrix

| Feature | OpenHands | Ellipsis | Copilot Agent |
|---------|-----------|----------|---------------|
| Open Source | ✅ Yes | ❌ No | ❌ No |
| Self-Hostable | ✅ Yes | ❌ No | ❌ No |
| Issue → PR | ✅ Yes | ❌ No | ✅ Yes |
| PR Review | ❌ No | ✅ Yes | ✅ Limited |
| Bug Fixes | ✅ Yes | ✅ Yes | ✅ Yes |
| Free Tier | ✅ Yes | ✅ Public repos | ❌ Subscription |
| Multi-Provider | ✅ Yes | ❌ No | ❌ No |

## Integration with Existing Infrastructure

### With Auto-Claude

Auto-Claude handles scheduled maintenance while autonomous agents handle
on-demand work:

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Autonomous AI Stack                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  On-Demand (Issue/PR Triggered)                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  OpenHands   │  │  Ellipsis    │  │   Copilot    │          │
│  │ Issue → PR   │  │  PR Review   │  │    Agent     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                  │
│  Scheduled (launchd/Cron)                                        │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │ Auto-Claude  │  │  Dependabot  │                             │
│  │ Maintenance  │  │   Updates    │                             │
│  └──────────────┘  └──────────────┘                             │
│                                                                  │
│  Monitoring (OTEL → Cribl → Splunk)                             │
└─────────────────────────────────────────────────────────────────┘
```

### With OrbStack/Kubernetes

OpenHands can be deployed as a Kubernetes CronJob or Job:

```yaml
# Example K8s Job for OpenHands
apiVersion: batch/v1
kind: Job
metadata:
  name: openhands-issue-123
spec:
  template:
    spec:
      containers:
        - name: openhands
          image: docker.all-hands.dev/all-hands-ai/openhands:latest
          env:
            - name: ANTHROPIC_API_KEY
              valueFrom:
                secretKeyRef:
                  name: ai-secrets
                  key: anthropic-api-key
          args:
            - python
            - -m
            - openhands.core.main
            - -t
            - "Implement feature X"
      restartPolicy: Never
```

## Security Considerations

### OpenHands

- Runs in isolated Docker containers
- API keys stored in GitHub Secrets
- Limited to repository permissions

### Ellipsis

- SOC II Type I certified
- Does not persist source code
- Runs in private AWS VPC

### Copilot Agent

- GitHub-native security model
- Uses existing repository permissions
- Audit logs available

## Troubleshooting

### OpenHands Issues

**Workflow not triggering:**

- Check that `ai:openhands` label exists
- Verify `ANTHROPIC_API_KEY` secret is set
- Check Actions are enabled for the repository

**Agent fails to complete:**

- Review workflow logs
- Increase timeout if needed
- Check API rate limits

### Ellipsis Issues

**Not reviewing PRs:**

- Verify GitHub App is installed
- Check repository access permissions
- Review Ellipsis dashboard for errors

## Related Documentation

- [LLM Agents](LLM-AGENTS.md) - numtide/llm-agents.nix packages
- [Crush](CRUSH.md) - Interactive AI coding agent
- [Monitoring](MONITORING.md) - Observability stack

## References

- [OpenHands Documentation](https://docs.openhands.dev/)
- [OpenHands GitHub Action](https://github.com/marketplace/actions/openhands-ai-action)
- [Ellipsis.dev](https://www.ellipsis.dev/)
- [Ellipsis Documentation](https://docs.ellipsis.dev/)
- [GitHub Copilot](https://github.com/features/copilot)
