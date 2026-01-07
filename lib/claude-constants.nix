# Claude Code Constants
#
# Centralized constants for Claude Code configuration.
# Single source of truth to avoid duplication and drift.
_:

rec {
  # Commands excluded from auto-discovery due to high token cost
  # These can still be used via /skill if needed
  #
  # Defined here as single source of truth, referenced by:
  # - modules/home-manager/ai-cli/claude-config.nix (command filtering)
  # - modules/home-manager/ai-cli/claude/settings.nix (activation warning)
  excludedCommands = [
    "auto-claude" # Very large, not actively used due to token issues
    "shape-issues" # Should be a plugin, not a command
    "consolidate-issues" # Large, rarely used
    "init-change" # Deprecated, replaced by init-worktree
  ];

  # Formatted list for display in warnings/logs
  # Example: "auto-claude, shape-issues, consolidate-issues, init-change"
  excludedCommandsFormatted = builtins.concatStringsSep ", " excludedCommands;
}
