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
2. Get the enrollment token
3. Create the K8s secret:

   ```bash
   kubectl -n monitoring create secret generic cribl-cloud-config \
     --from-literal=master-url="https://YOUR_ORG.cribl.cloud:4200" \
     --from-literal=auth-token="YOUR_FLEET_TOKEN"
   ```

4. Update deployment: change `CRIBL_DIST_MODE` to `managed-edge`

## Troubleshooting

```bash
# Check logs
kubectl -n monitoring logs -l app=cribl-edge

# Access UI
kubectl -n monitoring port-forward svc/cribl-edge 9000:9000
# Then open http://localhost:9000
```
