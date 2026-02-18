# Kubernetes Monitoring Infrastructure

> **Moved:** Kubernetes manifests are now managed in the
> [kubernetes-monitoring](https://github.com/JacobPEvans/kubernetes-monitoring) repository.

## Setup

1. Clone the repository:

   ```bash
   cd ~/git
   mkdir -p kubernetes-monitoring
   cd kubernetes-monitoring
   git clone git@github.com:JacobPEvans/kubernetes-monitoring.git main
   ```

2. Follow the [Deployment Guide](https://github.com/JacobPEvans/kubernetes-monitoring/blob/main/docs/DEPLOYMENT.md).

## Helper Scripts

These scripts are still provided by nix-config when `monitoring.kubernetes.enable = true`:

| Script | Description |
|--------|-------------|
| `monitoring-deploy` | Deploy monitoring stack from kubernetes-monitoring repo |
| `monitoring-status` | Show monitoring namespace pod status |
| `monitoring-logs` | Tail all monitoring pod logs |

## Configuration

In your nix-config host configuration:

```nix
monitoring = {
  enable = true;
  kubernetes.enable = true;
  # kubernetes.repoPath = "~/git/kubernetes-monitoring/main";  # default
  # kubernetes.context = "orbstack";  # default
  otel.enable = true;
};
```

## Related Documentation

- [kubernetes-monitoring README](https://github.com/JacobPEvans/kubernetes-monitoring#readme)
- [Main Monitoring Overview](../MONITORING.md)
