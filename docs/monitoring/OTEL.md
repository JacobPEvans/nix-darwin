# OpenTelemetry Configuration

OTEL instrumentation for Claude Code metrics and log/event export.

## Overview

Claude Code exports metrics and log/event data via OTLP to the OrbStack Kubernetes
OTEL Collector, which forwards to Cribl Edge → Cribl Cloud → Splunk via HEC.

**Data flow:**

```text
Claude Code --OTLP/gRPC--> OTEL Collector (:30317 NodePort)
  --OTLP/HTTP--> Cribl Edge Managed (:9420)
    --TLS--> Cribl Cloud (:4200)
      --HEC--> Splunk (:8088)
```

A secondary path: the OTEL Collector `filelog` receiver tails `/home/claude-user/.claude/logs/*.jsonl`
on the host (mounted into the collector via a `hostPath` volume or equivalent bind mount),
providing raw log ingestion in parallel.

## Claude Code OTEL

### Configuration

OTEL environment variables are set by `modules/monitoring/default.nix` when both
`monitoring.enable = true` and `monitoring.otel.enable = true`.

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `1` | Master switch — nothing exports without this |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://localhost:30317` | NodePort gRPC endpoint |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `grpc` | Explicit protocol selection |
| `OTEL_METRICS_EXPORTER` | `otlp` | Enable metric export |
| `OTEL_LOGS_EXPORTER` | `otlp` | Enable log/event export |
| `OTEL_SERVICE_NAME` | `claude-code` | Service identifier |
| `OTEL_METRICS_INCLUDE_SESSION_ID` | `true` | Attach session ID to metrics |
| `OTEL_METRICS_INCLUDE_VERSION` | `true` | Attach app version to metrics |
| `OTEL_METRICS_INCLUDE_ACCOUNT_UUID` | `true` | Attach account UUID to metrics |
| `OTEL_LOG_USER_PROMPTS` | `1` | Log full prompt content (opt-in, privacy-sensitive) |
| `OTEL_LOG_TOOL_DETAILS` | `1` | Log MCP server/tool names (opt-in) |
| `OTEL_RESOURCE_ATTRIBUTES` | `host.name=macbook-m4` | Resource attributes |

### Nix Options

```nix
monitoring.otel = {
  enable = true;
  endpoint = "http://localhost:30317";  # default
  protocol = "grpc";                    # default
  logPrompts = true;                    # privacy-sensitive
  logToolDetails = true;
  resourceAttributes = {
    "host.name" = "macbook-m4";
  };
};
```

### What Claude Code Exports

**Note**: Claude Code exports metrics and log/events only — not traces/spans.

#### Metrics (via OTLP)

| Metric | Description |
|--------|-------------|
| `claude_code.session.count` | Sessions started |
| `claude_code.lines_of_code.count` | Lines added/removed |
| `claude_code.pull_request.count` | PRs created |
| `claude_code.commit.count` | Git commits |
| `claude_code.cost.usage` | USD cost by model |
| `claude_code.token.usage` | Tokens by type and model |
| `claude_code.code_edit_tool.decision` | Edit accept/reject |
| `claude_code.active_time.total` | Active seconds |

#### Events/Logs (via OTLP)

| Event | Description |
|-------|-------------|
| `claude_code.user_prompt` | Prompt submission (content if `logPrompts=true`) |
| `claude_code.tool_result` | Tool execution results |
| `claude_code.api_request` | API calls with cost/tokens |
| `claude_code.api_error` | API failures |
| `claude_code.tool_decision` | Permission decisions |

### Enabling OTEL

1. Ensure OTEL Collector is running (see [Kubernetes](./KUBERNETES.md))
2. Rebuild: `nix flake check && sudo darwin-rebuild switch --flake .`
3. Open a new shell to pick up new session variables
4. Start a Claude Code session

### Verification

```bash
# 1. Verify env vars are set
env | grep -E 'OTEL|TELEMETRY'

# 2. Verify OTEL Collector pod is running
kubectl --context orbstack -n monitoring get pods -l app=otel-collector

# 3. Verify NodePort is reachable via HTTP OTLP endpoint (30318)
# Note: curl cannot speak gRPC, so we check the HTTP endpoint (30318) as a proxy
# for overall collector reachability. Claude Code uses the gRPC endpoint (30317).
curl -s -o /dev/null -w '%{http_code}' http://localhost:30318/v1/logs

# 4. After a Claude session, check collector received data
kubectl --context orbstack -n monitoring logs -l app=otel-collector --tail=50
# Look for: claude_code.* metric/log entries
```

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
  filelog:
    include: [/home/claude-user/.claude/logs/*.jsonl]
```

### NodePort Services

| Port | Protocol | Purpose |
|------|----------|---------|
| `30317` | gRPC | OTLP gRPC receiver (used by Claude Code) |
| `30318` | HTTP | OTLP HTTP receiver |

### Exporters

```yaml
exporters:
  otlphttp:
    endpoint: http://cribl-edge:9420
  debug:
    verbosity: normal
```

### Service Pipeline

```yaml
service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlphttp, debug]
    logs:
      receivers: [otlp, filelog]
      processors: [batch]
      exporters: [otlphttp, debug]
```

## Troubleshooting

### No Data Appearing

1. Check `CLAUDE_CODE_ENABLE_TELEMETRY=1` is set — this is the master switch:

   ```bash
   env | grep TELEMETRY
   ```

2. Verify all OTEL vars are set:

   ```bash
   env | grep OTEL
   ```

3. Verify collector is running:

   ```bash
   kubectl --context orbstack -n monitoring get pods -l app=otel-collector
   ```

4. Check NodePort connectivity (HTTP OTLP endpoint; gRPC on 30317 cannot be tested with curl):

   ```bash
   curl -v http://localhost:30318/v1/logs
   ```

5. Check collector logs for incoming data:

   ```bash
   kubectl --context orbstack -n monitoring logs -l app=otel-collector --tail=100
   ```

### Wrong Endpoint

- `localhost:4317` = ClusterIP, **not reachable from macOS host**
- `localhost:30317` = NodePort, reachable from macOS host via OrbStack

### Missing Attributes

1. Verify `OTEL_RESOURCE_ATTRIBUTES` is set with `env | grep OTEL`
2. Check processors (metric/log processors) aren't dropping attributes
3. Ensure exporters preserve all fields

## Related Documentation

- [Kubernetes Setup](./KUBERNETES.md)
- [Splunk Queries](./SPLUNK.md)
- [Main Monitoring Overview](../MONITORING.md)
