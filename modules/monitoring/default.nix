# Monitoring Infrastructure Module
#
# Aggregates all monitoring components:
# - Kubernetes manifests for OrbStack cluster
# - OTEL Collector configuration
# - Cribl Edge configuration
# - Splunk deployment
#
# Usage:
#   imports = [ ./modules/monitoring ];
#
# This module primarily manages K8s manifest files and helper scripts.
# The actual K8s resources are deployed via kubectl.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.monitoring;
in
{
  options.monitoring = {
    enable = lib.mkEnableOption "Monitoring infrastructure";

    kubernetes = {
      enable = lib.mkEnableOption "Kubernetes-based monitoring stack";

      namespace = lib.mkOption {
        type = lib.types.str;
        default = "monitoring";
        description = "Kubernetes namespace for monitoring components";
      };

      context = lib.mkOption {
        type = lib.types.str;
        default = "orbstack";
        description = "kubectl context to use for deployments";
      };
    };

    otel = {
      enable = lib.mkEnableOption "OpenTelemetry Collector";

      endpoint = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:4317";
        description = "OTEL Collector gRPC endpoint";
      };
    };

    cribl = {
      enable = lib.mkEnableOption "Cribl Edge log shipper";

      cloudUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Cribl Cloud organization URL (e.g., https://your-org.cribl.cloud:4200)";
      };
    };

    splunk = {
      enable = lib.mkEnableOption "Local Splunk instance";

      storageSize = lib.mkOption {
        type = lib.types.str;
        default = "50Gi";
        description = "Persistent volume size for Splunk data";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      # Deploy K8s manifest files to a known location
      file = {
        ".config/monitoring/k8s/namespace.yaml".source = ./k8s/namespace.yaml;
        ".config/monitoring/k8s/kustomization.yaml".source = ./k8s/kustomization.yaml;

        # OTEL Collector manifests (substitute homeDir for hostPath volumes)
        ".config/monitoring/k8s/otel-collector/deployment.yaml".source = pkgs.substituteAll {
          src = ./k8s/otel-collector/deployment.yaml;
          homeDir = config.home.homeDirectory;
        };
        ".config/monitoring/k8s/otel-collector/configmap.yaml".source = ./k8s/otel-collector/configmap.yaml;
        ".config/monitoring/k8s/otel-collector/service.yaml".source = ./k8s/otel-collector/service.yaml;

        # Cribl Edge manifests (substitute homeDir for hostPath volumes)
        ".config/monitoring/k8s/cribl-edge/deployment.yaml".source = pkgs.substituteAll {
          src = ./k8s/cribl-edge/deployment.yaml;
          homeDir = config.home.homeDirectory;
        };
        ".config/monitoring/k8s/cribl-edge/service.yaml".source = ./k8s/cribl-edge/service.yaml;

        # Splunk manifests
        ".config/monitoring/k8s/splunk/statefulset.yaml".source = ./k8s/splunk/statefulset.yaml;
        ".config/monitoring/k8s/splunk/service.yaml".source = ./k8s/splunk/service.yaml;
        ".config/monitoring/k8s/splunk/configmap.yaml".source = ./k8s/splunk/configmap.yaml;
      };

      # Helper script to deploy/update the monitoring stack
      packages = [
        (pkgs.writeShellScriptBin "monitoring-deploy" ''
          #!/usr/bin/env bash
          set -euo pipefail

          MANIFEST_DIR="$HOME/.config/monitoring/k8s"
          CONTEXT="${cfg.kubernetes.context}"
          NAMESPACE="${cfg.kubernetes.namespace}"

          echo "Deploying monitoring stack to context: $CONTEXT"

          # Apply all resources via kustomization (includes namespace.yaml)
          kubectl --context "$CONTEXT" apply -k "$MANIFEST_DIR"

          echo "Monitoring stack deployed to namespace: $NAMESPACE"
          echo ""
          echo "Access Splunk UI: kubectl --context $CONTEXT -n $NAMESPACE port-forward svc/splunk 8000:8000"
          echo "Then open: http://localhost:8000"
        '')

        (pkgs.writeShellScriptBin "monitoring-status" ''
          #!/usr/bin/env bash
          set -euo pipefail

          CONTEXT="${cfg.kubernetes.context}"
          NAMESPACE="${cfg.kubernetes.namespace}"

          echo "=== Monitoring Stack Status ==="
          echo ""
          kubectl --context "$CONTEXT" -n "$NAMESPACE" get all
          echo ""
          echo "=== Pod Logs (last 10 lines each) ==="
          for pod in $(kubectl --context "$CONTEXT" -n "$NAMESPACE" get pods -o jsonpath='{.items[*].metadata.name}'); do
            echo ""
            echo "--- $pod ---"
            kubectl --context "$CONTEXT" -n "$NAMESPACE" logs "$pod" --tail=10 2>/dev/null || echo "(no logs yet)"
          done
        '')
      ];

      # Set OTEL environment variables for Claude Code
      sessionVariables = lib.mkIf cfg.otel.enable {
        OTEL_EXPORTER_OTLP_ENDPOINT = cfg.otel.endpoint;
        OTEL_SERVICE_NAME = "claude-code";
      };
    };
  };
}
