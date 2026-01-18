# Kubernetes Monitoring Infrastructure

OrbStack Kubernetes deployment for the monitoring stack.

## Prerequisites

- OrbStack installed with Kubernetes enabled
- `kubectl` configured to use OrbStack context
- Secrets prepared (see [Initial Setup](#initial-setup))

## Initial Setup

Before deploying, create the required secrets:

```bash
# Create namespace first
kubectl apply -f modules/monitoring/k8s/namespace.yaml

# Create Cribl Cloud config secret (copy full URL from Cribl Cloud console)
kubectl -n monitoring create secret generic cribl-cloud-config \
  --from-literal=master-url='tls://YOUR_AUTH_TOKEN@YOUR_ORG.cribl.cloud?group=YOUR_FLEET'
```

**Important**: Splunk is no longer supported on ARM64/macOS environments. All logging is shipped to Cribl Cloud for long-term storage and analysis.

## OTEL Collector

Receives OTEL traces/metrics from Claude Code and forwards to Cribl Edge.

### Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 4317 | gRPC | OTLP receiver |
| 4318 | HTTP | OTLP receiver |
| 13133 | HTTP | Health check |

### Deployment

```bash
kubectl apply -f modules/monitoring/k8s/otel-collector/
```

### Verification

```bash
# Check pod status
kubectl -n monitoring get pods -l app=otel-collector

# View logs
kubectl -n monitoring logs -l app=otel-collector

# Check health
kubectl -n monitoring port-forward svc/otel-collector 13133:13133
curl http://localhost:13133/health
```

### External Access

For local access from macOS, use the NodePort service:

```bash
# gRPC endpoint
# http://localhost:30317

# HTTP endpoint
# http://localhost:30318
```

## Cribl Edge

Ships logs to Cribl Cloud Stream for processing and routing.

**Setup:** Log into Cribl Cloud → Create Fleet → Generate token → Store in K8s secret → Deploy

**Ports:** 9420 (OTEL receiver), 9000 (Management UI)

**Deploy:** `kubectl apply -f modules/monitoring/k8s/cribl-edge/`

**Volumes:** `~/.claude/logs/`, `~/Library/Logs/Ollama/`, `~/logs/`

**Verify:**

```bash
kubectl -n monitoring get pods -l app=cribl-edge
kubectl -n monitoring logs -l app=cribl-edge
kubectl -n monitoring port-forward svc/cribl-edge 9000:9000
```

Also check the Cribl Cloud console for Edge node enrollment status.

## Full Stack Deployment

Deploy all components at once using kustomization:

```bash
kubectl apply -k modules/monitoring/k8s/
```

## Troubleshooting

### Pods Not Starting

```bash
# Check events
kubectl -n monitoring get events --sort-by='.lastTimestamp'

# Describe pod for details
kubectl -n monitoring describe pod <pod-name>
```

### Secret Issues

```bash
# Verify secrets exist
kubectl -n monitoring get secrets

# Check secret contents (be careful with sensitive data)
kubectl -n monitoring get secret cribl-cloud-config -o yaml
```

### Network Issues

```bash
# Test internal connectivity
kubectl -n monitoring run --rm -it debug --image=busybox -- sh
# Inside pod:
wget -qO- http://otel-collector:13133/health
```

### Resource Constraints

Check if OrbStack has sufficient resources allocated:

- Recommended: 4 CPU cores, 8GB RAM for full stack

## Related Documentation

- [OTEL Configuration](./OTEL.md)
- [Splunk Queries](./SPLUNK.md)
- [Main Monitoring Overview](../MONITORING.md)
