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

    # Superpowers - comprehensive Claude enhancement suite
    "superpowers@superpowers-marketplace" = true;
    "double-shot-latte@superpowers-marketplace" = true; # User requested restore
    "superpowers-lab@superpowers-marketplace" = true; # User requested add
    "superpowers-developing-for-claude-code@superpowers-marketplace" = true; # User requested restore

    # REMOVED - redundant or unused:
    # devops-automator - too generic, terraform plugins better
    # double-check - unnecessary
    # infrastructure-maintainer - too generic
    # monitoring-observability-specialist - splunk repos don't need this
  };
}
