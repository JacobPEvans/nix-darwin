# Terraform/Terragrunt Development Shell
#
# Complete infrastructure-as-code environment with all tools found in
# terraform-proxmox repo plus popular community tools.
#
# NOTE: This shell allows unfree packages (Terraform uses BSL license).
# OpenTofu is included as a fully open-source alternative.
#
# Included tools:
# - terraform: Core IaC tool
# - terragrunt: Terraform wrapper for DRY configurations
# - opentofu: Open source Terraform fork
# - terraform-docs: Auto-generate documentation from modules
# - tflint: Terraform linter for best practices
# - checkov: Security scanner for infrastructure code
# - terrascan: Security scanner by Tenable
# - tfsec: Security scanner (now part of Trivy)
# - trivy: Comprehensive vulnerability scanner
# - infracost: Cloud cost estimation
# - pre-commit: Git hooks framework
# - markdownlint-cli2: Markdown linting
#
# Usage:
#   1. Copy this file to your project
#   2. Create .envrc with "use flake"
#   3. Run: direnv allow
#
# Or manually: nix develop

{
  description = "Terraform/Terragrunt development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          # Terraform uses BSL license (unfree)
          config.allowUnfree = true;
        };
      });
    in
    {
      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # === CORE IaC TOOLS ===
            terraform              # HashiCorp Terraform
            terragrunt             # Terraform wrapper (DRY configs)
            opentofu               # Open source Terraform fork

            # === DOCUMENTATION ===
            terraform-docs         # Auto-generate docs from modules

            # === LINTING & FORMATTING ===
            tflint                 # Terraform linter
            # TFLint plugins (uncomment as needed for your providers):
            # tflint-plugins.tflint-ruleset-aws
            # tflint-plugins.tflint-ruleset-google

            # === SECURITY SCANNERS ===
            checkov                # Security/compliance scanner (Bridgecrew)
            terrascan              # Security scanner (Tenable)
            tfsec                  # Security scanner (Aqua)
            trivy                  # Comprehensive vulnerability scanner

            # === COST ESTIMATION ===
            infracost              # Cloud cost estimates

            # === UTILITIES ===
            # NOTE: pre-commit and markdownlint-cli2 are in common system packages
            jq                     # JSON processor
            yq                     # YAML processor
          ];

          shellHook = ''
            echo "Terraform/Terragrunt development environment ready"
            echo ""
            echo "Core tools:"
            echo "  - terraform $(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1)"
            echo "  - terragrunt $(terragrunt --version 2>/dev/null | head -1)"
            echo "  - opentofu $(tofu version 2>/dev/null | head -1)"
            echo ""
            echo "Validation & Docs:"
            echo "  - terraform-docs, tflint"
            echo ""
            echo "Security scanners:"
            echo "  - checkov, terrascan, tfsec, trivy"
            echo ""
            echo "Cost estimation:"
            echo "  - infracost"
            echo ""
            echo "Tip: Run 'pre-commit install' to enable git hooks"
          '';
        };
      });
    };
}
