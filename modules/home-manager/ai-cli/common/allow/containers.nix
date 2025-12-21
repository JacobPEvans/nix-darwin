# Container and Orchestration Commands
#
# Auto-approved commands for Docker and Kubernetes.
# Imported by allow.nix - do not use directly.

_:

{
  # --- Docker ---
  docker = [
    "docker --version"
    "docker ps"
    "docker images"
    "docker logs"
    "docker inspect"
    "docker start"
    "docker stop"
    "docker restart"
    "docker build"
    "docker pull"
    "docker push"
    "docker tag"
    "docker compose"
    "docker info"
    "docker cp"
    "docker context inspect"
    "docker context ls"
    "docker context show"
    "docker network inspect"
    "docker network ls"
    "docker system df"
    "docker volume inspect"
    "docker volume ls"
  ];

  # --- Kubernetes ---
  kubernetes = [
    "kubectl version"
    "kubectl get"
    "kubectl describe"
    "kubectl logs"
    "kubectl port-forward"
    "kubectl config"
    "kubectl rollout"
    "helm version"
    "helm list"
    "helm repo"
    "helm search"
  ];
}
