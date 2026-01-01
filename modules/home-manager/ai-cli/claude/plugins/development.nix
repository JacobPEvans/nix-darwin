# Development & Engineering Plugins
#
# CRITICAL: All plugins use "@claude-code-workflows" marketplace
# ============================================================================
# GitHub repo: wshobson/agents
# Manifest name: "claude-code-workflows" (from .claude-plugin/marketplace.json)
# Plugin format: "plugin-name@claude-code-workflows"
#
# Example: "backend-development@claude-code-workflows" ✓ CORRECT
# NOT: "backend-development@agents" ✗ WRONG
#
# See docs/TESTING-MARKETPLACES.md for verification
# ============================================================================

_:

{
  enabledPlugins = {
    # ========================================================================
    # Core Development Workflows
    # ========================================================================
    "backend-development@claude-code-workflows" = true;
    "full-stack-orchestration@claude-code-workflows" = true;

    # ========================================================================
    # Git & PR Workflows
    # ========================================================================
    "git-pr-workflows@claude-code-workflows" = true;

    # ========================================================================
    # Testing & Quality Assurance
    # ========================================================================
    "unit-testing@claude-code-workflows" = true;
    "tdd-workflows@claude-code-workflows" = true;
    "code-review-ai@claude-code-workflows" = true;
    "comprehensive-review@claude-code-workflows" = true;
    "performance-testing-review@claude-code-workflows" = true;

    # ========================================================================
    # Code Quality & Maintenance
    # ========================================================================
    "code-refactoring@claude-code-workflows" = true;
    "codebase-cleanup@claude-code-workflows" = true;
    "debugging-toolkit@claude-code-workflows" = true;
    "error-debugging@claude-code-workflows" = true;

    # ========================================================================
    # Documentation & Architecture
    # ========================================================================
    "code-documentation@claude-code-workflows" = true;
    "documentation-generation@claude-code-workflows" = true;

    # ========================================================================
    # API Development
    # ========================================================================
    "api-scaffolding@claude-code-workflows" = true;
    "api-testing-observability@claude-code-workflows" = true;

    # ========================================================================
    # AI & ML Development (4 plugins)
    # ========================================================================
    "llm-application-dev@claude-code-workflows" = true;
    "agent-orchestration@claude-code-workflows" = true;
    "context-management@claude-code-workflows" = true;
    "machine-learning-ops@claude-code-workflows" = true;

    # ========================================================================
    # Data Engineering
    # ========================================================================
    "data-engineering@claude-code-workflows" = true;
    "data-validation-suite@claude-code-workflows" = true;

    # ========================================================================
    # Language Support
    # ========================================================================
    "python-development@claude-code-workflows" = true;
    "javascript-typescript@claude-code-workflows" = true;
    "systems-programming@claude-code-workflows" = true;

    # ========================================================================
    # Utilities
    # ========================================================================
    "dependency-management@claude-code-workflows" = true;
  };
}
