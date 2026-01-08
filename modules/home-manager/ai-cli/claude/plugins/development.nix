# Development Plugins - Terraform/Nix/Python/Shell + selected marketplace plugins

_:

{
  enabledPlugins = {
    # ========================================================================
    # Claude Code Workflows - Core Development Tools
    # ========================================================================

    # Backend (Python, Shell)
    "backend-development@claude-code-workflows" = true;

    # Testing
    "unit-testing@claude-code-workflows" = true;
    "tdd-workflows@claude-code-workflows" = true;

    # Code Quality
    "code-refactoring@claude-code-workflows" = true;
    "codebase-cleanup@claude-code-workflows" = true;

    # Agent Orchestration (user requested)
    "agent-orchestration@claude-code-workflows" = true;

    # Observability - Keep distributed-tracing and slo-implementation, exclude prometheus/grafana
    "observability-monitoring@claude-code-workflows" = true;

    # ========================================================================
    # Claude Code Workflows - Explicitly Excluded (set to false)
    # ========================================================================
    # These are not needed for Terraform/Nix/Python development

    # Event Sourcing/CQRS - Not used (user will create separate Ansible repo)
    "microservices-patterns@claude-code-workflows" = false;
    "projection-patterns@claude-code-workflows" = false;
    "saga-orchestration@claude-code-workflows" = false;
    "cqrs-implementation@claude-code-workflows" = false;

    # Temporal Workflows - Not currently in use
    "workflow-orchestration-patterns@claude-code-workflows" = false;
    "temporal-python-testing@claude-code-workflows" = false;

    # Event Store Design - Not needed
    "event-store-design@claude-code-workflows" = false;

    # Removed in previous phase
    "gitlab-ci-patterns@claude-code-workflows" = false;
    "mcp-cli@claude-code-workflows" = false;

    # Other excluded
    "full-stack-orchestration@claude-code-workflows" = false;
    "code-documentation@claude-code-workflows" = false;
    "api-scaffolding@claude-code-workflows" = false;
    "api-testing-observability@claude-code-workflows" = false;
    "llm-application-dev@claude-code-workflows" = false;
    "context-management@claude-code-workflows" = false;
    "machine-learning-ops@claude-code-workflows" = false;
    "data-engineering@claude-code-workflows" = false;
    "data-validation-suite@claude-code-workflows" = false;
    "systems-programming@claude-code-workflows" = false;
    "dependency-management@claude-code-workflows" = false;

    # ========================================================================
    # JacobPEvans Personal Plugins - ALL ENABLED
    # ========================================================================
    # Enable all plugins from user's custom marketplace
    "git-rebase-workflow@jacobpevans-cc-plugins" = true;
    "webfetch-guard@jacobpevans-cc-plugins" = true;
    "markdown-validator@jacobpevans-cc-plugins" = true;
    "token-validator@jacobpevans-cc-plugins" = true;
    "issue-limiter@jacobpevans-cc-plugins" = true;

    # ========================================================================
    # Claude Skills Marketplace - Selected Suite Plugins
    # ========================================================================
    # Note: Claude Skills uses suite plugins that contain multiple skills.
    # Install suite plugins, not individual skills.

    # API Skills - includes rest-api-design, graphql-implementation, etc.
    "api-skills@claude-skills" = true;

    # Testing Skills - includes playwright-testing, vitest-testing, jest-generator, etc.
    "testing-skills@claude-skills" = true;

    # Security Skills - includes vulnerability-scanning, csrf-protection, xss-prevention, etc.
    "security-skills@claude-skills" = true;

    # Data Skills - includes recommendation-engine, sql-query-optimization, etc.
    "data-skills@claude-skills" = true;

    # Auth Skills - includes better-auth, clerk-auth, oauth-implementation
    "auth-skills@claude-skills" = true;
  };
}
