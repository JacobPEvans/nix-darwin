# OpenTelemetry Collector

Receives traces, metrics, and logs from Claude Code and other sources.

## Receivers

| Receiver | Port | Protocol | Purpose |
|----------|------|----------|---------|
| OTLP gRPC | 4317 | gRPC | Application traces/metrics |
| OTLP HTTP | 4318 | HTTP | Application traces/metrics |
| Filelog | - | Local | Claude log files (JSONL) |

## Exporters

| Exporter | Destination | Purpose |
|----------|-------------|---------|
| `otlphttp` | Cribl Edge (9420) | Forward to log pipeline |
| `debug` | stdout | Debug output |
| `splunk_hec` | Splunk (8088) | Direct to Splunk (disabled) |

## Configuration

Edit `configmap.yaml` to modify:

- Receivers (add new log sources)
- Processors (batch size, resource attributes)
- Exporters (destinations)
- Pipelines (which exporters receive which data)

## Health Check

Port 13133 provides health status (`/` endpoint).
