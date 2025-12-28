# Official Anthropic Plugins
#
# Plugins from the claude-plugins-official marketplace
# These provide core Claude Code functionality

_:

{
  enabledPlugins = {
    # ========================================================================
    # Git Workflow
    # ========================================================================
    "commit-commands@claude-plugins-official" = true;

    # ========================================================================
    # Code Review & Quality
    # ========================================================================
    "code-review@claude-plugins-official" = true;
    "pr-review-toolkit@claude-plugins-official" = true;

    # ========================================================================
    # Feature Development
    # ========================================================================
    "feature-dev@claude-plugins-official" = true;

    # ========================================================================
    # Security
    # ========================================================================
    "security-guidance@claude-plugins-official" = true;

    # ========================================================================
    # Plugin & Hook Development
    # ========================================================================
    "plugin-dev@claude-plugins-official" = true;
    "hookify@claude-plugins-official" = true;

    # ========================================================================
    # SDK Development
    # ========================================================================
    "agent-sdk-dev@claude-plugins-official" = true;

    # ========================================================================
    # UI/UX Design
    # ========================================================================
    "frontend-design@claude-plugins-official" = true;

    # ========================================================================
    # Output Styles
    # ========================================================================
    "explanatory-output-style@claude-plugins-official" = true;
    "learning-output-style@claude-plugins-official" = true;

    # ========================================================================
    # Integrations
    # ========================================================================
    "github@claude-plugins-official" = true;
    "typescript-lsp@claude-plugins-official" = true;
    "greptile@claude-plugins-official" = true;
    "slack@claude-plugins-official" = true;
  };
}
