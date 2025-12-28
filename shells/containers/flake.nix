# Container Development & Orchestration Shell
#
# Complete container ecosystem environment with Docker, container building,
# registry tools, and Kubernetes orchestration.
#
# Usage:
#   nix develop
#   # or with direnv: echo "use flake" > .envrc && direnv allow

{
  description = "Container development, building, and orchestration environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
            };
          }
        );
    in
    {
      devShells = forAllSystems (
        { pkgs }:
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # === Container Runtime ===
              docker

              # === Container Building ===
              buildkit

              # === Container Registry ===
              crane
              skopeo

              # === Kubernetes Orchestration ===
              kubectl
              kubernetes-helm-wrapped

              # === Development ===
              git
              python3
              jq
              yq
            ];

            shellHook = ''
              {
                echo "═══════════════════════════════════════════════════════════════"
                echo "Container Development & Orchestration Environment"
                echo "═══════════════════════════════════════════════════════════════"
                echo ""
                echo "Container Runtime & Building:"
                echo "  - docker: $(docker --version 2>/dev/null)"
                echo "  - buildkit: $(buildctl --version 2>/dev/null || echo 'available')"
                echo ""
                echo "Container Registry:"
                echo "  - crane: $(crane version 2>/dev/null || echo 'available')"
                echo "  - skopeo: $(skopeo --version 2>/dev/null)"
                echo ""
                echo "Kubernetes Orchestration:"
                echo "  - kubectl: $(kubectl version --client --short 2>/dev/null || echo 'available')"
                echo "  - helm: $(helm version 2>/dev/null || echo 'available')"
                echo ""
                echo "Getting Started:"
                echo "  1. Build images with: docker build -t <image>:<tag> ."
                echo "  2. Query registries with: crane ls <registry>/<image>"
                echo "  3. Deploy with: helm install <release> <chart>"
                echo "  4. Manage cluster: kubectl apply -f <manifests>"
                echo ""
              }
            '';
          };
        }
      );
    };
}
