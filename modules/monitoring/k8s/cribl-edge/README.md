# Cribl Edge

Log shipper and processing engine for routing logs to Cribl Cloud or other destinations.

## Modes

| Mode | Description | Config |
|------|-------------|--------|
| `edge` | Standalone operation (default) | No cloud connection |
| `managed-edge` | Managed by Cribl Cloud | Requires cloud credentials |

## Ports

| Port | Purpose | Binding |
|------|---------|---------|
| 9420 | API/OTEL input | localhost only |
| 9000 | Web UI | localhost only |

## Volume Mounts

Host paths are mounted read-only for log collection:

- `/var/log/claude` - Claude Code logs
- `/var/log/ollama` - Ollama server logs
- `/var/log/terminal` - Terminal session logs

## Connecting to Cribl Cloud

1. Create a Fleet in Cribl Cloud console
2. Copy the full connection URL from the Fleet enrollment page
3. Create the K8s secret with the **complete URL** (includes auth token and group):

   ```bash
   kubectl -n monitoring create secret generic cribl-cloud-config \
     --from-literal=master-url="tls://YOUR_AUTH_TOKEN@YOUR_ORG.cribl.cloud?group=YOUR_FLEET"
   ```

   Example format: `tls://otiQTiu...@main-org.cribl.cloud?group=default_fleet`

4. Apply the deployment (already configured for `managed-edge` mode)

## Troubleshooting

```bash
# Check logs
kubectl -n monitoring logs -l app=cribl-edge

# Access UI
kubectl -n monitoring port-forward svc/cribl-edge 9000:9000
# Then open http://localhost:9000
```
