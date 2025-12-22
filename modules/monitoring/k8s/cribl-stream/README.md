# Cribl Stream

Full-featured data routing and transformation platform.

## Modes

| Mode | Description |
|------|-------------|
| `master` | Leader node (current config) |
| `worker` | Worker node (for scaling) |
| `single` | Single-instance mode |

## Ports

| Port | Purpose |
|------|---------|
| 9000 | Web UI / API |
| 10080 | Data inputs (HTTP, Splunk HEC, etc.) |
| 4200 | Leader-to-worker communication |

## Access

```bash
# Port-forward to access UI
kubectl -n monitoring port-forward svc/cribl-stream 9000:9000
# Then open http://localhost:9000

# Or use NodePort (if service-ui.yaml deployed)
# http://localhost:30900
```

## Default Credentials

- Username: `admin`
- Password: Set via `cribl-stream-admin` secret, or `admin` if not set

## Configuration

Stream configuration is managed through the UI at `/` or via API.

Key features:

- Routes: Define data routing rules
- Pipelines: Transform data in-flight
- Destinations: Configure output targets (Splunk, S3, etc.)
- Sources: Configure input sources (syslog, HTTP, etc.)
