# Infrastructure & DevOps Plugins
#
# CRITICAL: Marketplace Names
# ============================================================================
# Plugins from multiple marketplaces - marketplace names match manifest values:
#
# 1. wshobson/agents → "@claude-code-workflows"
#    Example: "cloud-infrastructure@claude-code-workflows"
#    NOT "@agents" ✗
#
# 2. basher83/lunar-claude → "@lunar-claude"
# 3. jeremylongshore/claude-code-plugins-plus → "@claude-code-plugins-plus"
#
# See docs/TESTING-MARKETPLACES.md for verification
# ============================================================================

_:

{
  enabledPlugins = {
    # ========================================================================
    # Lunar Claude - Infrastructure Automation
    # ========================================================================
    "proxmox-infrastructure@lunar-claude" = true; # User actively uses Proxmox
    "ansible-workflows@lunar-claude" = true; # User actively uses Ansible

    # Removed - redundant with commit-commands@official:
    # "git-workflow@lunar-claude" = true;  # Redundant with commit-commands:commit-push-pr

    # ========================================================================
    # Claude Code Plugins Plus - IaC Tools
    # ========================================================================
    "infrastructure-as-code-generator@claude-code-plugins-plus" = true; # User actively uses Terraform
    "terraform-module-builder@claude-code-plugins-plus" = true; # User actively uses Terraform

    # ========================================================================
    # WSHobson Agents - Cloud & Infrastructure (Keep - active DevOps user)
    # ========================================================================
    "cloud-infrastructure@claude-code-workflows" = true;
    "kubernetes-operations@claude-code-workflows" = true;
    "cicd-automation@claude-code-workflows" = true;
    "deployment-strategies@claude-code-workflows" = true;
    "deployment-validation@claude-code-workflows" = true;

    # ========================================================================
    # WSHobson Agents - Observability & Monitoring (Keep - active DevOps user)
    # ========================================================================
    "observability-monitoring@claude-code-workflows" = true;

    # ========================================================================
    # WSHobson Agents - Security (Removed - large plugins rarely used)
    # ========================================================================
    # "security-scanning@claude-code-workflows" = true;  # 26k+ tokens, includes threat-mitigation-mapping
    # "security-compliance@claude-code-workflows" = true;
    # "backend-api-security@claude-code-workflows" = true;

    # ========================================================================
    # WSHobson Agents - Database & Performance (Keep - useful for DevOps)
    # ========================================================================
    "database-design@claude-code-workflows" = true;
    "application-performance@claude-code-workflows" = true;
  };
}
