# Terraform/Terragrunt Development Shell
#
# Complete IaC environment: Terraform, Terragrunt, OpenTofu, Ansible, security scanners,
# Proxmox tools, and utilities. See TOOLS.md for complete tool listing.
#
# Usage: nix develop (or direnv allow with .envrc)
# NOTE: Allows unfree packages (Terraform BSL license)

{
  description = "Terraform/Terragrunt development environment";

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
              # Terraform uses BSL license (unfree)
              config.allowUnfree = true;
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
              # ═══════════════════════════════════════════════════════════════
              # CORE IaC TOOLS
              # ═══════════════════════════════════════════════════════════════
              terraform # HashiCorp Terraform (main IaC tool)
              terragrunt # Terraform wrapper for DRY configurations
              opentofu # Open-source Terraform fork

              # ═══════════════════════════════════════════════════════════════
              # TERRAFORM DOCUMENTATION & LINTING
              # ═══════════════════════════════════════════════════════════════
              terraform-docs # Auto-generate module documentation
              tflint # Terraform linter & best practices checker
              # Uncomment TFLint plugins as needed:
              # tflint-plugins.tflint-ruleset-aws
              # tflint-plugins.tflint-ruleset-google

              # ═══════════════════════════════════════════════════════════════
              # SECURITY & COMPLIANCE SCANNING
              # ═══════════════════════════════════════════════════════════════
              checkov # Security/compliance scanning (Bridgecrew)
              terrascan # Infrastructure security scanning (Tenable)
              tfsec # Terraform security scanning (Aqua)
              trivy # Comprehensive vulnerability scanner

              # ═══════════════════════════════════════════════════════════════
              # COST ESTIMATION
              # ═══════════════════════════════════════════════════════════════
              infracost # Cloud cost estimation tool

              # ═══════════════════════════════════════════════════════════════
              # CONFIGURATION MANAGEMENT (Ansible/Molecule)
              # ═══════════════════════════════════════════════════════════════
              ansible # Agentless configuration management
              ansible-lint # Ansible playbook linting
              molecule # Ansible role testing framework
              python3 # Python runtime for Ansible, Molecule, pip packages
              git # Version control (explicit for compatibility)

              # ═══════════════════════════════════════════════════════════════
              # CLOUD & CONTAINER TOOLS
              # ═══════════════════════════════════════════════════════════════
              awscli2 # AWS CLI for S3 state backend & credential management
              docker # Container runtime (required for Molecule testing)

              # ═══════════════════════════════════════════════════════════════
              # PROXMOX VE TOOLS
              # ═══════════════════════════════════════════════════════════════
              proxmox-backup-client # Proxmox Backup Server client utilities
              # NOTE: pvesh, qm, pct are host-only tools (access via SSH)
              # Use Python proxmoxer library or Terraform providers for API access

              # ═══════════════════════════════════════════════════════════════
              # UTILITIES & PROCESSORS
              # ═══════════════════════════════════════════════════════════════
              jq # JSON processor & formatter
              yq # YAML processor & formatter
              # NOTE: pre-commit & markdownlint-cli2 are available in system packages
            ];

            shellHook = ''
              cat <<'BANNER'
              ═══════════════════════════════════════════════════════════════
              Terraform/Terragrunt & Ansible Development Environment
              ═══════════════════════════════════════════════════════════════
              BANNER

              echo "Terraform: $(terraform version | head -1 | cut -d' ' -f2)"
              echo "Terragrunt: $(terragrunt --version | cut -d' ' -f3)"
              echo "OpenTofu: $(tofu version | head -1 | cut -d' ' -f2)"
              echo ""
              echo "Tools: terraform-docs, tflint, checkov, terrascan, tfsec, trivy"
              echo "Config: ansible, molecule, python, aws-cli, docker, proxmox-backup-client"
              echo "Docs: See TOOLS.md for complete tool listing"
              echo ""
              echo "Quick start: aws configure → terragrunt init → pre-commit install"
              echo ""
            '';
          };
        }
      );
    };
}
