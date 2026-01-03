# Experimental Plugins
#
# WARNING: Experimental plugins may have autonomous behavior
#
# Ralph-wiggum creates autonomous iteration loops that repeatedly
# feed Claude the same prompt until completion criteria are met.
# Use with caution in production environments.
#
# CRITICAL: Plugin Reference Format
# ============================================================================
# Format: "plugin-name@marketplace-name"
#
# The marketplace-name MUST match the key in marketplaces.nix, which MUST
# match the `name` field from the marketplace's .claude-plugin/marketplace.json
#
# Examples:
#   - "ralph-wiggum@claude-plugins-official" ✓ CORRECT
#
# How to verify: See docs/TESTING-MARKETPLACES.md
# ============================================================================

_:

{
  enabledPlugins = {
    # ========================================================================
    # Autonomous Iteration
    # ========================================================================
    # Ralph-wiggum: Autonomous iteration loop with self-referential feedback
    # - Creates while-true bash loops that preserve work between iterations
    # - Claude sees its own past work via files and git history
    # - Terminates when completion promise found or max iterations reached
    #
    # Commands: /ralph-loop, /cancel-ralph
    # Use cases: Well-defined tasks, TDD workflows, iterative refinement
    # Avoid: Production debugging, tasks requiring human judgment
    "ralph-wiggum@claude-plugins-official" = true;
  };
}
