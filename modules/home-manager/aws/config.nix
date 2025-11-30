# AWS CLI Configuration
#
# Manages AWS CLI configuration via home-manager.
# The config file sets default region and output format.
#
# Files managed:
#   ~/.aws/config - AWS CLI profiles and settings
#
# Files NOT managed (contain secrets):
#   ~/.aws/credentials - Access keys (use aws-vault instead)
#
# Security:
#   - Use aws-vault for credential management (uses macOS Keychain)
#   - Never store access keys in ~/.aws/credentials directly
#   - Use IAM Identity Center (SSO) or short-term credentials
#
# Usage:
#   aws configure list                      # Show current configuration
#   aws sts get-caller-identity             # Verify credentials
#   aws-vault exec <profile> -- aws s3 ls   # Execute with vault credentials
#
# Profile inheritance:
#   - [default] is the literal default profile (used when no --profile specified)
#   - Other profiles do NOT inherit from [default] automatically
#   - Use source_profile to chain profiles for role assumption
#
# Common config options (per profile):
#   region           - AWS region (us-east-2, etc.)
#   output           - Format: json, yaml, text, table
#   cli_pager        - Pager for output (empty string to disable)
#   cli_auto_prompt  - Auto-prompt mode: on, on-partial, off
#   retry_mode       - Retry strategy: legacy, standard, adaptive
#   max_attempts     - Max retry attempts (default: 5)
#   duration_seconds - Session duration for assumed roles (900-43200)
#
# SSO options (IAM Identity Center):
#   sso_start_url    - Portal URL
#   sso_region       - SSO endpoint region
#   sso_account_id   - AWS account ID
#   sso_role_name    - Role to assume
#
# Role assumption options:
#   role_arn         - Role ARN to assume
#   source_profile   - Profile with credentials for assuming role
#   mfa_serial       - MFA device ARN (required if role needs MFA)
#   external_id      - External ID for cross-account roles

{ config, ... }:

{
  # ~/.aws/config - AWS CLI configuration
  ".aws/config".text = ''
    # Default profile - used when no --profile is specified
    [default]
    region = us-east-2
    output = json

    # Development environment
    [profile dev]
    region = us-east-2
    output = json

    # Test environment
    [profile test]
    region = us-east-2
    output = json

    # Terraform automation
    [profile terraform]
    region = us-east-2
    output = json

    # Cribl environment
    [profile cribl]
    region = us-east-2
    output = json

    # Splunk environment
    [profile splunk]
    region = us-east-2
    output = json
  '';
}
