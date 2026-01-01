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
    "proxmox-infrastructure@lunar-claude" = true;
    "git-workflow@lunar-claude" = true;
    "ansible-workflows@lunar-claude" = true;

    # ========================================================================
    # Claude Code Plugins Plus - IaC Tools
    # ========================================================================
    "infrastructure-as-code-generator@claude-code-plugins-plus" = true;
    "terraform-module-builder@claude-code-plugins-plus" = true;

    # ========================================================================
    # WSHobson Agents - Cloud & Infrastructure
    # ========================================================================
    "cloud-infrastructure@claude-code-workflows" = true;
    "kubernetes-operations@claude-code-workflows" = true;
    "cicd-automation@claude-code-workflows" = true;
    "deployment-strategies@claude-code-workflows" = true;
    "deployment-validation@claude-code-workflows" = true;

    # ========================================================================
    # WSHobson Agents - Observability & Monitoring
    # ========================================================================
    "observability-monitoring@claude-code-workflows" = true;

    # ========================================================================
    # WSHobson Agents - Security
    # ========================================================================
    "security-scanning@claude-code-workflows" = true;
    "security-compliance@claude-code-workflows" = true;
    "backend-api-security@claude-code-workflows" = true;

    # ========================================================================
    # WSHobson Agents - Database & Performance
    # ========================================================================
    "database-design@claude-code-workflows" = true;
    "application-performance@claude-code-workflows" = true;
  };
}
