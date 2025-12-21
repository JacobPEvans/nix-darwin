# Cloud and Infrastructure as Code Commands
#
# Auto-approved commands for AWS, Terraform, and Terragrunt.
# Imported by allow.nix - do not use directly.

_:

{
  # --- AWS ---
  aws = [
    "aws --version"
    "aws-vault --version"
    "aws-vault list"
    "aws sts get-caller-identity"
    "aws s3 ls"
    "aws ec2 describe-instances"
    "aws lambda list-functions"
    "aws cloudformation list-stacks"
    "aws cloudformation describe-stacks"
    "aws logs tail"
    "aws dynamodb list-tables"
    "aws dynamodb scan"
    "aws dynamodb describe-table"
  ];

  # --- Terraform ---
  terraform = [
    "terraform --version"
    "terraform version"
    "terraform init"
    "terraform validate"
    "terraform fmt"
    "terraform plan"
    "terraform show"
    "terraform state list"
    "terraform state show"
    "terraform providers"
    "terraform output"
    "terraform graph"
  ];

  # --- Terragrunt ---
  terragrunt = [
    "terragrunt --version"
    "terragrunt version"
    "terragrunt init"
    "terragrunt validate"
    "terragrunt plan"
    "terragrunt show"
    "terragrunt state list"
    "terragrunt state show"
    "terragrunt output"
    "terragrunt graph-dependencies"
    "terragrunt hclfmt"
  ];
}
