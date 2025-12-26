# Terraform/Terragrunt Development Shell
#
# Complete infrastructure-as-code environment with all tools found in
# terraform-proxmox repo plus popular community tools.
#
# NOTE: This shell allows unfree packages (Terraform uses BSL license).
# OpenTofu is included as a fully open-source alternative.
#
# ════════════════════════════════════════════════════════════════
# TERRAFORM/TERRAGRUNT TOOLS
# ════════════════════════════════════════════════════════════════
# - terraform: Core IaC tool
# - terragrunt: Terraform wrapper for DRY configurations
# - opentofu: Open source Terraform fork
# - terraform-docs: Auto-generate documentation from modules
# - tflint: Terraform linter for best practices
#
# ════════════════════════════════════════════════════════════════
# SECURITY SCANNERS
# ════════════════════════════════════════════════════════════════
# - checkov: Security/compliance scanner (Bridgecrew)
# - terrascan: Security scanner (Tenable)
# - tfsec: Security scanner (Aqua)
# - trivy: Comprehensive vulnerability scanner
# - infracost: Cloud cost estimation
#
# ════════════════════════════════════════════════════════════════
# CONFIGURATION MANAGEMENT & TESTING (Ansible/Molecule)
# ════════════════════════════════════════════════════════════════
# - ansible: Configuration management and automation
# - ansible-lint: Ansible playbook linting
# - molecule: Ansible role testing framework
# - python3: Runtime for Ansible, Molecule, and pip packages
#
# ════════════════════════════════════════════════════════════════
# CLOUD & STATE MANAGEMENT
# ════════════════════════════════════════════════════════════════
# - aws-cli: AWS CLI for S3 backend and credential management
# - docker: Container runtime for Molecule testing
#
# ════════════════════════════════════════════════════════════════
# GIT & UTILITIES
# ════════════════════════════════════════════════════════════════
# - pre-commit: Git hooks framework (also in system packages)
# - markdownlint-cli2: Markdown linting (also in system packages)
# - jq: JSON processor
# - yq: YAML processor
# - git: Version control
#
# Usage:
#   1. nix develop (from project root)
#   2. Or create .envrc with "use flake" and run direnv allow
#
# Python packages (from nixpkgs):
#   - ansible: Core automation tool
#   - molecule: Testing framework
#   - docker: Python Docker client (for Molecule)

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
              # UTILITIES & PROCESSORS
              # ═══════════════════════════════════════════════════════════════
              jq # JSON processor & formatter
              yq # YAML processor & formatter
              # NOTE: pre-commit & markdownlint-cli2 are available in system packages
            ];

            shellHook = ''
              echo "═══════════════════════════════════════════════════════════════"
              echo "Terraform/Terragrunt & Ansible Development Environment"
              echo "═══════════════════════════════════════════════════════════════"
              echo ""
              echo "INFRASTRUCTURE AS CODE:"
              echo "  - terraform: $(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1)"
              echo "  - terragrunt: $(terragrunt --version 2>/dev/null | cut -d' ' -f2)"
              echo "  - opentofu: $(tofu version 2>/dev/null | head -1)"
              echo ""
              echo "VALIDATION & DOCUMENTATION:"
              echo "  - terraform-docs (auto-generate module docs)"
              echo "  - tflint (Terraform linting)"
              echo ""
              echo "SECURITY SCANNING:"
              echo "  - checkov, terrascan, tfsec, trivy"
              echo ""
              echo "CONFIGURATION MANAGEMENT:"
              echo "  - ansible: $(ansible --version 2>/dev/null | head -1)"
              echo "  - ansible-lint: $(ansible-lint --version 2>/dev/null)"
              echo "  - molecule: $(molecule --version 2>/dev/null)"
              echo "  - python: $(python3 --version 2>/dev/null)"
              echo ""
              echo "CLOUD & CONTAINER:"
              echo "  - aws-cli: $(aws --version 2>/dev/null)"
              echo "  - docker: $(docker --version 2>/dev/null)"
              echo ""
              echo "UTILITIES:"
              echo "  - jq (JSON), yq (YAML), git (version control)"
              echo ""
              echo "GETTING STARTED:"
              echo "  1. Configure AWS credentials: aws configure"
              echo "  2. Configure Proxmox API token (environment variable or file)"
              echo "  3. Initialize Terraform: terragrunt init"
              echo "  4. Setup pre-commit hooks: pre-commit install"
              echo ""
            '';
          };
        }
      );
    };
}
