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

# For Cribl Cloud (if using managed mode) - use full URL from Cribl Cloud console
kubectl -n monitoring create secret generic cribl-cloud-config \
  --from-literal=master-url="tls://YOUR_AUTH_TOKEN@YOUR_ORG.cribl.cloud?group=YOUR_FLEET"
```

## Host Path Mounts

OrbStack automatically maps macOS paths into containers:

| Container Path | Host Path | Purpose |
|----------------|-----------|---------|
| `/var/log/claude` | `~/.claude/logs` | Claude Code logs |
| `/var/log/ollama` | `~/Library/Logs/Ollama` | Ollama logs |
| `/var/log/terminal` | `~/logs` | Terminal session logs |
