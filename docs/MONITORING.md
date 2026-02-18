# Monitoring Infrastructure

Comprehensive observability for Claude Code autonomous agents and AI development workflows.

## Architecture Overview

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                           Log Sources                                    │
├─────────────────────────────────────────────────────────────────────────┤
│  Auto-Claude     │  Claude Code    │  Ollama        │  Terminal         │
│  ~/.claude/logs/ │  OTEL native    │  ~/Library/... │  ~/logs/          │
└────────┬─────────┴────────┬────────┴───────┬────────┴────────┬──────────┘
         │                  │                │                 │
         ▼                  ▼                ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    OrbStack Kubernetes Cluster                           │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐                                     │
│  │ OTEL         │  │ Cribl Edge   │                                     │
│  │ Collector    │──│ (log shipper)│                                     │
│  └──────┬───────┘  └──────┬───────┘                                     │
│         │                 │                                              │
└─────────┼─────────────────┼──────────────────────────────────────────────┘
          │                 │
          ▼                 ▼
┌─────────────────┐  ┌─────────────────┐
│ Cribl Cloud     │  │ Cribl Lake      │
│ Stream          │──│ (long-term)     │
└─────────────────┘  └─────────────────┘
```

## Quick Reference

| Component | Purpose | Location |
|-----------|---------|----------|
| Auto-Claude Logs | Run history, JSONL events | `~/.claude/logs/` |
| Slack Notifications | Real-time alerts | Configured per repository |
| OTEL Collector | Trace/metric aggregation | K8s: `monitoring` namespace |
| Cribl Edge | Log shipping to cloud | K8s: `monitoring` namespace |
| Ollama | Log enrichment/parsing | Local or K8s |

---

## Log Sources

### 1. Auto-Claude Logs

**Location:** `~/.claude/logs/`

**Files:**

| File Pattern | Format | Content |
|--------------|--------|---------|
| `{repo}_{timestamp}.jsonl` | JSONL | Full Claude CLI output |
| `summary.log` | Text | Human-readable run summaries |
| `failures.log` | Text | Failed runs with errors |
| `launchd-{repo}.log` | Text | LaunchAgent stdout |
| `launchd-{repo}.err` | Text | LaunchAgent stderr |

**JSONL Event Types:**

```json
{"event": "run_started", "repo": "nix-config", "budget": 25.0, "timestamp": "..."}
{"event": "subagent_spawned", "agent_id": "...", "type": "ci-fixer", "parent": "orchestrator"}
{"event": "subagent_completed", "agent_id": "...", "exit_code": 0, "duration_sec": 120, "cost": 1.23}
{"event": "context_checkpoint", "usage_pct": 45, "tokens_used": 90000, "tokens_remaining": 110000}
{"event": "budget_checkpoint", "spent": 5.50, "budget": 25.00, "remaining_pct": 78}
{"event": "task_completed", "task": "Fix CI failure", "pr": "#123", "cost": 1.23}
{"event": "task_blocked", "task": "Implement feature", "reason": "Requires user input"}
{"event": "run_completed", "duration_minutes": 45, "total_cost": 12.50, "tasks_completed": 5}
```

### 2. Claude Code (Interactive)

**OTEL Traces:** When OTEL is configured, Claude Code emits traces for:

- Tool invocations (Read, Write, Bash, etc.)
- Model API calls with latency
- Session lifecycle events

**Environment Variables:**

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
export OTEL_SERVICE_NAME="claude-code"
export OTEL_RESOURCE_ATTRIBUTES="host.name=$(hostname),user.name=$(whoami)"
```

### 3. Ollama Logs

**Location:** `~/Library/Logs/Ollama/`

**Files:**

- `ollama.log` - Server stdout
- `ollama.error.log` - Server stderr

### 4. Terminal Session Logs

**Location:** `~/logs/`

**Pattern:** `terminal_YYYY-MM-DD_HH-MM.log`

---

## Slack Notifications

### Configuration

Slack notifications are configured per repository in `modules/home-manager/ai-cli/claude-config.nix`:

```nix
programs.claude.autoClaude.repositories = {
  ai-assistant-instructions = {
    # ...
    slackChannel = "C0AXXXXXXXX";  # Get from BWS: slack-channel-ai-assistant-instructions
  };
  nix = {
    # ...
    slackChannel = "C0AXXXXXXXX";  # Get from BWS: slack-channel-nix
  };
};
```

### Secret Setup

The Slack bot token must be stored in Bitwarden Secrets Manager:

1. **Create the secret** in Bitwarden Secrets Manager:
   - Name: `auto-claude-slack-bot-token`
   - Value: Your Slack bot token (starts with `xoxb-`)

2. **Or use a custom secret ID** by setting:

   ```bash
   export BWS_SLACK_SECRET_ID="your-custom-secret-id"
   ```

### Required Slack App Scopes

Your Slack app needs these OAuth scopes:

- `chat:write` - Post messages
- `chat:write.public` - Post to public channels without joining

### Notification Types

| Event | Description | Threading |
|-------|-------------|-----------|
| `run_started` | Auto-claude begins | Parent message |
| `task_started` | Subagent spawned | Thread reply |
| `task_completed` | Task finished (with PR link) | Thread reply |
| `task_blocked` | Task failed/blocked | Thread reply |
| `run_completed` | Full summary | Parent update + thread |

### Testing Slack

```bash
# Trigger a manual run to test notifications
auto-claude-ctl run ai-assistant-instructions

# Check notification script directly
~/.claude/scripts/auto-claude-notify.py run_started \
  --repo test \
  --budget 1.0 \
  --run-id test-123 \
  --channel C0AXXXXXXXX
```

---

## Kubernetes Infrastructure

Kubernetes manifests have been extracted to a standalone repository:
**[kubernetes-monitoring](https://github.com/JacobPEvans/kubernetes-monitoring)**

### Quick Deploy

```bash
monitoring-deploy    # Deploy full stack (uses sops if secrets.enc.yaml exists)
monitoring-status    # Check pod status
monitoring-logs      # Tail all pod logs
```

See the [kubernetes-monitoring README](https://github.com/JacobPEvans/kubernetes-monitoring#readme) for full setup and configuration.

---

## OTEL Configuration

### Claude Code OTEL

OTEL environment variables are set in `modules/home-manager/ai-cli/claude/otel.nix`:

```nix
{
  home.sessionVariables = {
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4317";
    OTEL_SERVICE_NAME = "claude-code";
    OTEL_RESOURCE_ATTRIBUTES = "host.name=your-hostname";
  };
}
```

### Auto-Claude OTEL

The `auto-claude.sh` script emits OTEL spans for run lifecycle, subagent spawns, and checkpoints.

See [OTEL Configuration](./monitoring/OTEL.md) for full collector config and sampling options.

---

## Ollama Log Intelligence

### Architecture

Cribl Edge can route log copies to Ollama for AI-powered enrichment:

1. Error logs sent to Ollama for classification
2. Summaries generated for long runs
3. Anomaly detection on patterns

### Cribl Edge Pipeline

In Cribl Edge pipeline:

```javascript
// Enrich errors with AI classification
if (__e.event === 'error' || __e.level === 'error') {
  const response = await C.Fetch.request(
    'http://ollama:11434/api/generate',
    {
      method: 'POST',
      body: JSON.stringify({
        model: 'qwen3-next:latest',
        prompt: `Classify this error: ${__e.message}`,
        stream: false
      })
    }
  );
  __e.ai_classification = JSON.parse(response.body).response;
}
```

---

## Troubleshooting

| Issue | Check Command | Solution |
|-------|---------------|----------|
| Slack not sending | `bws secret get auto-claude-slack-bot-token` | Verify secret exists, channel ID starts with `C` |
| OTEL not receiving | `kubectl -n monitoring get pods -l app=otel-collector` | Check collector pod, port-forward 4317 |
| Cribl not shipping | `kubectl -n monitoring logs -l app=cribl-edge` | Check Cloud console for Edge enrollment |

**Quick diagnostics:**

```bash
# Test Slack notification
~/.claude/scripts/auto-claude-notify.py run_started --repo test --budget 1 --run-id test --channel CHANNEL_ID

# Test OTEL
otel-cli span --service test --name test-span
```

---

## Maintenance

```bash
# Clean old logs (30+ days)
find ~/.claude/logs -name "*.jsonl" -mtime +30 -delete

# Update Cribl Edge
kubectl -n monitoring set image deployment/cribl-edge cribl-edge=cribl/cribl:latest
```

---

## Detailed Documentation

For in-depth guides on each component:

- **[Kubernetes Setup](./monitoring/KUBERNETES.md)** - Full K8s deployment guide, secrets, troubleshooting
- **[Slack Notifications](./monitoring/SLACK.md)** - Notification types, Block Kit customization, testing
- **[OTEL Configuration](./monitoring/OTEL.md)** - Tracing, metrics, collector config, sampling
- **[Splunk Queries](./monitoring/SPLUNK.md)** - SPL queries, dashboards, saved searches
- **[Ollama Intelligence](./monitoring/OLLAMA.md)** - AI-powered log enrichment, Cribl pipelines

## Related Documentation

- [Auto-Claude Testing](../modules/home-manager/ai-cli/claude/TESTING.md)
- [Dependency Monitoring](DEPENDENCY-MONITORING.md)
- [Runbook](../RUNBOOK.md)
