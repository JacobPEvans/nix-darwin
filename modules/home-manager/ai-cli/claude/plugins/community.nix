# Community Marketplace Plugins
#
# Plugins from community-maintained marketplaces:
# - cc-marketplace: General development tools
# - bills-claude-skills: Git and GitHub workflows
# - superpowers-marketplace: Enhanced Claude capabilities

_:

{
  enabledPlugins = {
    # ========================================================================
    # CC Marketplace
    # ========================================================================
    "analyze-issue@cc-marketplace" = true;
    "create-worktrees@cc-marketplace" = true;
    "devops-automator@cc-marketplace" = true;
    "double-check@cc-marketplace" = true;

    # Removed duplicates (keeping official Anthropic versions):
    # "2-commit-fast@cc-marketplace" = true;  # Redundant with commit-commands@official
    # "code-review@cc-marketplace" = true;  # Redundant with code-review@official
    # "commit@cc-marketplace" = true;  # Redundant with commit-commands@official
    # "fix-github-issue@cc-marketplace" = true;  # Redundant with official PR toolkit
    # "fix-pr@cc-marketplace" = true;  # Redundant with official PR toolkit
    # "pr-issue-resolve@cc-marketplace" = true;  # Redundant with official PR toolkit

    # Keep for active usage:
    "infrastructure-maintainer@cc-marketplace" = true; # User actively does DevOps
    "monitoring-observability-specialist@cc-marketplace" = true; # User actively does DevOps
    "python-expert@cc-marketplace" = true; # User actively uses Python

    # Removed - optional:
    # "bug-detective@cc-marketplace" = true;  # Built-in debugging sufficient

    # ========================================================================
    # Bills Claude Skills
    # ========================================================================
    # Removed duplicates (keeping official Anthropic versions):
    # "git-workspace-init@bills-claude-skills" = true;  # Redundant with create-worktrees
    # "github-pr-resolver@bills-claude-skills" = true;  # Redundant with official PR toolkit

    # ========================================================================
    # Superpowers Marketplace
    # ========================================================================
    "superpowers@superpowers-marketplace" = true;
    "double-shot-latte@superpowers-marketplace" = true;
  };
}
