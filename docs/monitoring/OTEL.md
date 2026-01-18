# OpenTelemetry Configuration

OTEL instrumentation for Claude Code and Auto-Claude.

## Overview

OpenTelemetry provides distributed tracing and metrics for:

- Claude Code interactive sessions
- Auto-Claude autonomous runs
- Model API call latency
- Tool invocation timing
- Session lifecycle events

## Claude Code OTEL

### Environment Variables

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

### Traced Operations

When OTEL is configured, Claude Code emits traces for:

| Operation | Span Name | Attributes |
|-----------|-----------|------------|
| Tool invocation | `tool.{name}` | tool_name, duration_ms |
| Model API call | `model.request` | model, tokens, latency_ms |
| Session start | `session.start` | session_id, working_dir |
| Session end | `session.end` | session_id, duration_min |
| File read | `tool.read` | file_path, size_bytes |
| File write | `tool.write` | file_path, size_bytes |
| Bash command | `tool.bash` | command, exit_code |

### Enabling OTEL

1. Ensure OTEL Collector is running (see [Kubernetes](./KUBERNETES.md))
2. Set environment variables
3. Restart Claude Code

```bash
# Verify OTEL is configured
echo $OTEL_EXPORTER_OTLP_ENDPOINT
# Should output: http://localhost:4317
```

## Auto-Claude OTEL

The `auto-claude.sh` script emits OTEL spans for:

### Span Hierarchy

```text
auto_claude.run (root span)
├── auto_claude.context_checkpoint
├── auto_claude.budget_checkpoint
├── auto_claude.subagent
│   ├── auto_claude.subagent (nested)
│   └── ...
└── auto_claude.run_complete
```

### Span Attributes

#### Run Span

| Attribute | Type | Description |
|-----------|------|-------------|
| `repo` | string | Repository name |
| `run_id` | string | Unique run identifier |
| `budget` | float | Budget in USD |
| `duration_minutes` | float | Total run duration |
| `exit_code` | int | Final exit code |

#### Subagent Span

| Attribute | Type | Description |
|-----------|------|-------------|
| `agent_type` | string | Type of subagent |
| `agent_id` | string | Unique agent identifier |
| `parent_id` | string | Parent agent ID |
| `cost` | float | Cost in USD |
| `duration_sec` | int | Duration in seconds |

#### Checkpoint Spans

| Attribute | Type | Description |
|-----------|------|-------------|
| `usage_pct` | int | Context usage percentage |
| `tokens_used` | int | Tokens consumed |
| `tokens_remaining` | int | Tokens available |
| `spent` | float | Budget spent |
| `remaining_pct` | int | Budget remaining percentage |

## OTEL Collector Configuration

### Receivers

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
```

### Processors

```yaml
processors:
  batch:
    timeout: 10s
    send_batch_size: 1024

  # Optional: Add resource attributes
  resource:
    attributes:
      - key: deployment.environment
        value: development
        action: upsert
```

### Exporters

```yaml
exporters:
  # Forward to Cribl Edge
  otlphttp:
    endpoint: http://cribl-edge:9420

  # Debug logging
  debug:
    verbosity: normal
```

### Service Pipeline

```yaml
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, resource]
      exporters: [otlphttp, logging]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlphttp, logging]
```

## Testing OTEL

### Verify Collector Endpoint

```bash
# Check collector is receiving
curl http://localhost:4318/v1/traces \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"resourceSpans":[]}'
```

### Send Test Span

Using `otel-cli`:

```bash
# Install otel-cli
brew install otel-cli

# Send test span
otel-cli span \
  --service "test-service" \
  --name "test-span" \
  --endpoint "http://localhost:4317"
```

## Trace Sampling

For high-volume environments, configure sampling:

```yaml
processors:
  probabilistic_sampler:
    sampling_percentage: 10  # Sample 10% of traces

  tail_sampling:
    decision_wait: 10s
    policies:
      # Always sample errors
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      # Always sample slow operations
      - name: slow
        type: latency
        latency: {threshold_ms: 5000}
      # Sample 10% of everything else
      - name: default
        type: probabilistic
        probabilistic: {sampling_percentage: 10}
```

## Metrics Collection

### Available Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `claude.tool.duration_ms` | histogram | Tool invocation latency |
| `claude.model.tokens` | counter | Token usage |
| `claude.session.count` | counter | Session count |
| `claude.run.cost_usd` | counter | Cost accumulator |

### Prometheus Export

Add Prometheus exporter for metrics scraping:

```yaml
exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
    namespace: claude
```

## Troubleshooting

### No Traces Appearing

1. Check OTEL env vars are set:

   ```bash
   env | grep OTEL
   ```

2. Verify collector is running:

   ```bash
   kubectl -n monitoring get pods -l app=otel-collector
   ```

3. Check collector logs:

   ```bash
   kubectl -n monitoring logs -l app=otel-collector
   ```

### High Latency

1. Check batch processor settings
2. Verify network connectivity to collector
3. Consider sampling for high-volume workloads

### Missing Attributes

1. Verify resource attributes are set
2. Check span processors aren't dropping attributes
3. Ensure exporters preserve all fields

## Related Documentation

- [Kubernetes Setup](./KUBERNETES.md)
- [Splunk Queries](./SPLUNK.md)
- [Main Monitoring Overview](../MONITORING.md)
