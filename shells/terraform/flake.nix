# Terraform/Terragrunt/Ansible Development Shell
#
# Complete IaC environment for terraform-proxmox with Terraform, Terragrunt,
# Ansible, security scanners, and AWS/Docker integration.
#
# Usage:
#   nix develop
#   # or with direnv: echo "use flake" > .envrc && direnv allow

{
  description = "Terraform/Terragrunt/Ansible development environment";

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
              config.allowUnfree = true; # Terraform uses BSL license
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
              # === Infrastructure as Code ===
              terraform
              terragrunt
              opentofu
              terraform-docs
              tflint

              # === Security & Compliance ===
              checkov
              terrascan
              tfsec
              trivy
              infracost

              # === Configuration Management ===
              ansible
              ansible-lint
              molecule
              python3
              git

              # === Cloud & Containers ===
              awscli2
              docker

              # === Utilities ===
              jq
              yq
            ];

            shellHook = ''
              {
                echo "═══════════════════════════════════════════════════════════════"
                echo "Terraform/Terragrunt & Ansible Development Environment"
                echo "═══════════════════════════════════════════════════════════════"
                echo ""
                echo "Infrastructure as Code:"
                echo "  - terraform: $(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1)"
                echo "  - terragrunt: $(terragrunt --version 2>/dev/null | cut -d' ' -f3)"
                echo "  - opentofu: $(tofu version 2>/dev/null | head -1)"
                echo ""
                echo "Configuration Management:"
                echo "  - ansible: $(ansible --version 2>/dev/null | head -1)"
                echo "  - molecule: $(molecule --version 2>/dev/null)"
                echo ""
                echo "Cloud & Container:"
                echo "  - aws-cli: $(aws --version 2>/dev/null)"
                echo "  - docker: $(docker --version 2>/dev/null)"
                echo ""
                echo "Getting Started:"
                echo "  1. Configure AWS credentials: aws configure"
                echo "  2. Configure Proxmox API token (environment variable or file)"
                echo "  3. Initialize Terraform: terragrunt init"
                echo "  4. Setup pre-commit hooks: pre-commit install"
                echo ""
              } >&2
            '';
          };
        }
      );
    };
}
