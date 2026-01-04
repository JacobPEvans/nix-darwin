# Development Plugins - Minimal set for Terraform/Nix/Python/Shell

_:

{
  enabledPlugins = {
    # Backend (Python, Shell)
    "backend-development@claude-code-workflows" = true;

    # Testing
    "unit-testing@claude-code-workflows" = true;
    "tdd-workflows@claude-code-workflows" = true;

    # Code Quality
    "code-refactoring@claude-code-workflows" = true;
    "codebase-cleanup@claude-code-workflows" = true;

    # Agent Orchestration (user requested restore)
    "agent-orchestration@claude-code-workflows" = true;

    # REMOVED - not used based on repos:
    # full-stack-orchestration - no full-stack web apps
    # code-documentation - built-in sufficient
    # api-scaffolding - no API development repos
    # api-testing-observability - no API repos
    # llm-application-dev - no LLM app repos
    # context-management - unnecessary
    # machine-learning-ops - no ML repos
    # data-engineering - no data eng repos
    # data-validation-suite - no data eng repos
    # systems-programming - no Rust/Go repos
    # dependency-management - built-in sufficient
  };
}
