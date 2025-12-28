# Development & Engineering Plugins
#
# Software development tools from wshobson/agents:
# - Core development workflows (backend, frontend, full-stack)
# - Testing and quality assurance
# - Code documentation and architecture
# - Language-specific support
# - AI/ML development

_:

{
  enabledPlugins = {
    # ========================================================================
    # Core Development Workflows
    # ========================================================================
    "backend-development@agents" = true;
    "full-stack-orchestration@agents" = true;

    # ========================================================================
    # Git & PR Workflows
    # ========================================================================
    "git-pr-workflows@agents" = true;

    # ========================================================================
    # Testing & Quality Assurance
    # ========================================================================
    "unit-testing@agents" = true;
    "tdd-workflows@agents" = true;
    "code-review-ai@agents" = true;
    "comprehensive-review@agents" = true;
    "performance-testing-review@agents" = true;

    # ========================================================================
    # Code Quality & Maintenance
    # ========================================================================
    "code-refactoring@agents" = true;
    "codebase-cleanup@agents" = true;
    "debugging-toolkit@agents" = true;
    "error-debugging@agents" = true;

    # ========================================================================
    # Documentation & Architecture
    # ========================================================================
    "code-documentation@agents" = true;
    "documentation-generation@agents" = true;

    # ========================================================================
    # API Development
    # ========================================================================
    "api-scaffolding@agents" = true;
    "api-testing-observability@agents" = true;

    # ========================================================================
    # AI & ML Development (4 plugins)
    # ========================================================================
    "llm-application-dev@agents" = true;
    "agent-orchestration@agents" = true;
    "context-management@agents" = true;
    "machine-learning-ops@agents" = true;

    # ========================================================================
    # Data Engineering
    # ========================================================================
    "data-engineering@agents" = true;
    "data-validation-suite@agents" = true;

    # ========================================================================
    # Language Support
    # ========================================================================
    "python-development@agents" = true;
    "javascript-typescript@agents" = true;
    "systems-programming@agents" = true;

    # ========================================================================
    # Utilities
    # ========================================================================
    "dependency-management@agents" = true;
  };
}
