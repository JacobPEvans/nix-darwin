# Kubernetes Manifests

Kustomize-based Kubernetes manifests for the monitoring stack.

## Structure

```text
k8s/
├── kustomization.yaml      # Main kustomize config
├── namespace.yaml          # monitoring namespace
├── otel-collector/         # OpenTelemetry Collector
├── cribl-edge/             # Cribl Edge log shipper
└── splunk/                 # Local Splunk (disabled)
```

## Deployment

```bash
# Full stack
kubectl apply -k .

# Individual component
kubectl apply -f otel-collector/

# Verify
kubectl -n monitoring get pods
```

## Secrets Required

```bash
# For Splunk (if re-enabled)
kubectl -n monitoring create secret generic splunk-admin --from-literal=password="..."
kubectl -n monitoring create secret generic splunk-hec-token --from-literal=token="$(uuidgen)"

# For Cribl Cloud (if using managed mode)
kubectl -n monitoring create secret generic cribl-cloud-config \
  --from-literal=master-url="https://YOUR_ORG.cribl.cloud:4200" \
  --from-literal=auth-token="YOUR_FLEET_TOKEN"
```

## Host Path Mounts

OrbStack automatically maps macOS paths into containers:

| Container Path | Host Path | Purpose |
|----------------|-----------|---------|
| `/var/log/claude` | `~/.claude/logs` | Claude Code logs |
| `/var/log/ollama` | `~/Library/Logs/Ollama` | Ollama logs |
| `/var/log/terminal` | `~/logs` | Terminal session logs |
