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
  # Claude Code schema: { "id": { source: { source: "git", url: "..." } } }
  validateMarketplace =
    name: value:
    assert lib.assertMsg (builtins.isAttrs value)
      "Marketplace '${name}' must be an attrset, got ${builtins.typeOf value}";
    assert lib.assertMsg (
      value ? source && builtins.isAttrs value.source
    ) "Marketplace '${name}' must have a 'source' attrset";
    assert lib.assertMsg (
      value.source ? source && builtins.isString value.source.source
    ) "Marketplace '${name}.source' must have a 'source' string (git, github, npm, etc)";
    assert lib.assertMsg (
      value.source ? url && builtins.isString value.source.url
    ) "Marketplace '${name}.source' must have a 'url' string";
    true;

  # Official Anthropic plugin marketplaces
  # Plugins are fetched on-demand when enabled
  # Format: object with marketplace ID as key, containing nested source object
  marketplaces = {
    "anthropics/claude-code" = {
      source = {
        source = "git";
        url = "https://github.com/anthropics/claude-code.git";
      };
    };
    "anthropics/claude-plugins-official" = {
      source = {
        source = "git";
        url = "https://github.com/anthropics/claude-plugins-official.git";
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
    # Git workflow automation
    "commit-commands@anthropics/claude-code" = true;

    # Code review and quality
    "code-review@anthropics/claude-code" = true;
    "pr-review-toolkit@anthropics/claude-code" = true;

    # Feature development
    "feature-dev@anthropics/claude-code" = true;

    # Security
    "security-guidance@anthropics/claude-code" = true;

    # Plugin/hook development
    "plugin-dev@anthropics/claude-code" = true;
    "hookify@anthropics/claude-code" = true;

    # SDK development (useful for Claude Agent SDK work)
    "agent-sdk-dev@anthropics/claude-code" = true;

    # UI/UX design and guidance
    "frontend-design@anthropics/claude-code" = true;

    # Output styles for enhanced interaction
    "explanatory-output-style@anthropics/claude-code" = true;
    "learning-output-style@anthropics/claude-code" = true;

    # Model migration tools
    "claude-opus-4-5-migration@anthropics/claude-code" = true;

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
