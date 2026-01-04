# Community Marketplace Plugins
#
# Plugins from community-maintained marketplaces:
# - cc-marketplace: General development tools
# - superpowers-marketplace: Enhanced Claude capabilities

_:

{
  enabledPlugins = {
    # CC Marketplace - essential tools
    "analyze-issue@cc-marketplace" = true;
    "create-worktrees@cc-marketplace" = true;
    "python-expert@cc-marketplace" = true; # User actively uses Python

    # Superpowers - core plugin
    "superpowers@superpowers-marketplace" = true;

    # REMOVED - redundant or unused:
    # devops-automator - too generic, terraform plugins better
    # double-check - unnecessary
    # infrastructure-maintainer - too generic
    # monitoring-observability-specialist - splunk repos don't need this
    # double-shot-latte - unclear value
  };
}
