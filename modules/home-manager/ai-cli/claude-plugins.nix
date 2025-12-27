# Claude Code Plugins Configuration
#
# Manages official Anthropic plugins and commands from:
# - anthropics/claude-code (plugin marketplace)
# - anthropics/claude-cookbooks (commands and agents)
#
# Strategy:
# 1. Configure the official claude-code marketplace in settings.json
# 2. Enable specific plugins from the marketplace
# 3. Copy useful commands/agents from claude-cookbooks to ~/.claude/
#
# Schema validation: Assertions below ensure the settings.json structure
# matches what Claude Code expects. Build fails if format is wrong.
#
# Migration Notes:
# - Removed: "review-pr-ci" - replaced by code-review plugin (/code-review)

{
  config,
  lib,
  claude-code-plugins,
  claude-cookbooks,
  claude-plugins-official,
  anthropic-skills,
  ...
}:

let
  # Validate marketplace entry has correct nested structure
  # Claude Code schema: { "id": { source: { type: "git", url: "..." } } }
  # Note: 'type' field matches options.nix marketplaceModule definition
  validateMarketplace =
    name: value:
    assert lib.assertMsg (builtins.isAttrs value)
      "Marketplace '${name}' must be an attrset, got ${builtins.typeOf value}";
    assert lib.assertMsg (
      value ? source && builtins.isAttrs value.source
    ) "Marketplace '${name}' must have a 'source' attrset";
    assert lib.assertMsg (
      value.source ? type && builtins.isString value.source.type
    ) "Marketplace '${name}.source' must have a 'type' string (git, github, local)";
    assert lib.assertMsg (
      value.source ? url && builtins.isString value.source.url
    ) "Marketplace '${name}.source' must have a 'url' string";
    true;

  # Plugin marketplaces
  # Plugins are fetched on-demand when enabled
  #
  # IMPORTANT: Marketplace URL Format
  # ========================================================================
  # INPUT FORMAT (what we define here):
  #   type: "github"     (for GitHub repositories)
  #   url: "owner/repo"  (GitHub org/repo format, NOT full URL)
  #
  # OUTPUT FORMAT (after transformation via lib/claude-registry.nix):
  #   source: "github"
  #   repo: "marketplace-key"
  #
  # WHY THIS WORKS:
  # - The toClaudeMarketplaceFormat function (lib/claude-registry.nix line 25-37)
  #   converts both "github" and "git" types to "source: github" in settings.json
  # - The marketplace key (e.g., "anthropics/claude-code") becomes the repo value
  # - This ensures Claude Code can locate and fetch the marketplace
  #
  # DO NOT USE: Full GitHub URLs (e.g., https://github.com/owner/repo.git)
  # Those belong in native known_marketplaces.json, not Nix definitions.
  # ========================================================================
  marketplaces = {
    # ========================================================================
    # Official Anthropic Marketplaces
    # ========================================================================
    "anthropics/claude-code" = {
      source = {
        type = "github";
        url = "anthropics/claude-code";
      };
    };
    "claude-plugins-official" = {
      source = {
        type = "github";
        url = "anthropics/claude-plugins-official";
      };
    };

    # ========================================================================
    # Community Marketplaces
    # ========================================================================
    "cc-marketplace" = {
      source = {
        type = "github";
        url = "ananddtyagi/cc-marketplace";
      };
    };
    "bills-claude-skills" = {
      source = {
        type = "github";
        url = "BillChirico/bills-claude-skills";
      };
    };
    "superpowers-marketplace" = {
      source = {
        type = "github";
        url = "obra/superpowers-marketplace";
      };
    };
  };

  # Plugins to enable from the claude-code marketplace
  # These provide slash commands, agents, skills, and hooks
  #
  # Available plugins:
  #   - commit-commands: /commit, /commit-push-pr, /clean_gone
  #   - code-review: Multi-agent PR review with confidence scoring
  #   - feature-dev: 7-phase feature development workflow
  #   - pr-review-toolkit: Specialized review agents
  #   - security-guidance: Security monitoring hook
  #   - plugin-dev: Toolkit for creating Claude Code plugins
  #   - hookify: Custom hook creation
  #   - agent-sdk-dev: Agent SDK development kit
  #   - frontend-design: UI/UX design guidance
  #   - explanatory-output-style: Educational insights hook
  #   - learning-output-style: Interactive learning mode
  #   - claude-opus-4-5-migration: Model migration skill
  #   - ralph-wiggum: Autonomous iteration loops
  #
  enabledPlugins = {
    # ========================================================================
    # Anthropic Official Plugins (claude-plugins-official marketplace)
    # ========================================================================

    # Git workflow automation
    "commit-commands@claude-plugins-official" = true;

    # Code review and quality
    "code-review@claude-plugins-official" = true;
    "pr-review-toolkit@claude-plugins-official" = true;

    # Feature development
    "feature-dev@claude-plugins-official" = true;

    # Security
    "security-guidance@claude-plugins-official" = true;

    # Plugin/hook development
    "plugin-dev@claude-plugins-official" = true;
    "hookify@claude-plugins-official" = true;

    # SDK development (useful for Claude Agent SDK work)
    "agent-sdk-dev@claude-plugins-official" = true;

    # UI/UX design and guidance
    "frontend-design@claude-plugins-official" = true;

    # Output styles for enhanced interaction
    "explanatory-output-style@claude-plugins-official" = true;
    "learning-output-style@claude-plugins-official" = true;

    # GitHub and IDE integration
    "github@claude-plugins-official" = true;
    "typescript-lsp@claude-plugins-official" = true;

    # Code analysis and search
    "greptile@claude-plugins-official" = true;

    # Communication and integrations
    "slack@claude-plugins-official" = true;

    # ========================================================================
    # Community Marketplace Plugins
    # ========================================================================

    # CC Marketplace plugins
    "2-commit-fast@cc-marketplace" = true;
    "analyze-issue@cc-marketplace" = true;
    "bug-detective@cc-marketplace" = true;
    "code-review@cc-marketplace" = true;
    "commit@cc-marketplace" = true;
    "create-worktrees@cc-marketplace" = true;
    "devops-automator@cc-marketplace" = true;
    "double-check@cc-marketplace" = true;
    "fix-github-issue@cc-marketplace" = true;
    "fix-pr@cc-marketplace" = true;
    "infrastructure-maintainer@cc-marketplace" = true;
    "monitoring-observability-specialist@cc-marketplace" = true;
    "pr-issue-resolve@cc-marketplace" = true;
    "python-expert@cc-marketplace" = true;
    "sugar@cc-marketplace" = true;

    # Bills Claude Skills plugins
    "git-workspace-init@bills-claude-skills" = true;
    "github-pr-resolver@bills-claude-skills" = true;

    # Superpowers Marketplace plugins
    "superpowers@superpowers-marketplace" = true;
    "double-shot-latte@superpowers-marketplace" = true;

    # Experimental: Autonomous iteration loops (commented out by default)
    # "ralph-wiggum@anthropics/claude-code" = true;
  };

  # Commands from claude-cookbooks to install globally
  # These are copied directly to ~/.claude/commands/
  #
  # Note: The commit-commands plugin already provides /commit-push-pr
  # Additional repo-level commands (dedupe, oncall-triage) may exist in
  # anthropics/claude-code/.claude/commands/ but need verification.
  #
  # Migration Notes:
  # - Removed: "review-pr-ci" - replaced by code-review plugin (/code-review)
  # - Removed: "review-pr" - replaced by code-review plugin (/code-review)
  cookbookCommands = [
    "review-issue" # GitHub issue review
    "notebook-review" # Jupyter notebook review
    "model-check" # Model validation
    "link-review" # Link verification
  ];

  # Agents from claude-cookbooks to install globally
  # These are copied to ~/.claude/agents/
  cookbookAgents = [
    "code-reviewer" # Senior code review agent
  ];

  # Validate all marketplaces at evaluation time
  # If any marketplace has wrong structure, build fails with clear error
  validatedMarketplaces = lib.mapAttrs validateMarketplace marketplaces;

  # Force evaluation of validations
in
assert lib.all (x: x) (lib.attrValues validatedMarketplaces);
{
  # Plugin marketplace and enabled plugins configuration
  # Merged into settings.json by claude.nix
  pluginConfig = { inherit marketplaces enabledPlugins; };

  # Home-manager file entries for commands and agents
  # These copy files from the claude-cookbooks repo to ~/.claude/
  #
  # Helper function to reduce duplication (refactored per review feedback)
  # Creates file entries for a given type (command/agent) from a list of names
  files =
    let
      mkCookbookFileEntries =
        type: names:
        builtins.listToAttrs (
          map (name: {
            name = ".claude/${type}s/${name}.md";
            value = {
              source = "${claude-cookbooks}/.claude/${type}s/${name}.md";
            };
          }) names
        );
    in
    mkCookbookFileEntries "command" cookbookCommands // mkCookbookFileEntries "agent" cookbookAgents;
}
