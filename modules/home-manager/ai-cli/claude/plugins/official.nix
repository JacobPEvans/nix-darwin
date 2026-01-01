# Official Anthropic Plugins
#
# CRITICAL: Plugin Reference Format
# ============================================================================
# Format: "plugin-name@marketplace-name"
#
# The marketplace-name MUST match the key in marketplaces.nix, which MUST
# match the `name` field from the marketplace's .claude-plugin/marketplace.json
#
# Examples:
#   - "commit-commands@claude-plugins-official" ✓ CORRECT
#   - "example-skills@anthropic-agent-skills" ✓ CORRECT
#   - "example-skills@skills" ✗ WRONG (marketplace is anthropic-agent-skills, not skills)
#   - "backend-dev@agents" ✗ WRONG (marketplace is claude-code-workflows, not agents)
#
# How to verify: See docs/TESTING-MARKETPLACES.md
# ============================================================================

_:

{
  enabledPlugins = {
    # ========================================================================
    # Skills (from anthropics/skills repo, marketplace name: anthropic-agent-skills)
    # ========================================================================
    # Example skills including skill-creator for building custom skills
    "example-skills@anthropic-agent-skills" = true;
    # Document processing: xlsx, docx, pptx, pdf
    "document-skills@anthropic-agent-skills" = true;
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
