# Infrastructure & DevOps Plugins
#
# Infrastructure automation, cloud operations, and DevOps tools from:
# - lunar-claude: Proxmox, Ansible, Git workflows
# - claude-code-plugins-plus: IaC generation, Terraform
# - wshobson/agents: Cloud, Kubernetes, CI/CD, observability

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
    "cloud-infrastructure@agents" = true;
    "kubernetes-operations@agents" = true;
    "cicd-automation@agents" = true;
    "deployment-strategies@agents" = true;
    "deployment-validation@agents" = true;

    # ========================================================================
    # WSHobson Agents - Observability & Monitoring
    # ========================================================================
    "observability-monitoring@agents" = true;

    # ========================================================================
    # WSHobson Agents - Security
    # ========================================================================
    "security-scanning@agents" = true;
    "security-compliance@agents" = true;
    "backend-api-security@agents" = true;

    # ========================================================================
    # WSHobson Agents - Database & Performance
    # ========================================================================
    "database-design@agents" = true;
    "application-performance@agents" = true;
  };
}
