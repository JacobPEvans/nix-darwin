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
#
# Minimal set for actual usage patterns based on JacobPEvans repos:
# Terraform, Nix, Python, Splunk, Proxmox, Shell scripts

_:

{
  enabledPlugins = {
    # Git Workflow (essential)
    "commit-commands@claude-plugins-official" = true;

    # Code Review (essential)
    "code-review@claude-plugins-official" = true;
    "code-simplifier@claude-plugins-official" = true;
    "pr-review-toolkit@claude-plugins-official" = true;

    # Feature Development (useful)
    "feature-dev@claude-plugins-official" = true;

    # Security (useful for infra work)
    "security-guidance@claude-plugins-official" = true;

    # Plugin Development (user maintains claude-code-plugins repo)
    "plugin-dev@claude-plugins-official" = true;
    "hookify@claude-plugins-official" = true;

    # Language Servers & Developer Tools
    "pyright-lsp@claude-plugins-official" = true;

    # Workflow
    "ralph-loop@claude-plugins-official" = true;

    # External plugins (GitHub, Slack, Context7, etc.) moved to external.nix

    # REMOVED - unused or token-heavy:
    # document-skills - xlsx, docx, pptx, pdf not used
    # agent-sdk-dev - not building SDKs
    # frontend-design - no frontend repos
    # explanatory-output-style - output fluff
    # learning-output-style - output fluff
    # typescript-lsp - minimal TS usage
  };
}
