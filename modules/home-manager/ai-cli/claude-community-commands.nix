# Claude Code Community Commands
#
# Curated slash commands from the Claude Code community.
# These are stored directly in the Nix repo for version control and customization.
#
# Source attribution is included in each command file header.
#
# Current sources:
# - roksechs: GitHub Issue & PR Management lifecycle
#   https://gist.github.com/roksechs/3f24797d4b4e7519e18b7835c6d8a2d3
#
# Naming convention: Commands are prefixed with author attribution (e.g., 'rok-')
# to avoid conflicts with official Anthropic commands.

{ config, ... }:

let
  # Directory containing community command markdown files
  commandsDir = ./community-commands;

  # List of community commands to install
  # Each command is prefixed to avoid conflicts with official commands
  communityCommands = [
    "rok-shape-issues"       # Shape raw ideas into actionable GitHub Issues
    "rok-resolve-issues"     # Analyze and resolve GitHub Issues efficiently
    "rok-review-pr"          # Comprehensive PR review with quality checks
    "rok-respond-to-reviews" # Resolve PR review comments systematically
  ];

in
{
  # Home-manager file entries for community commands
  # These copy files from the local repo to ~/.claude/commands/
  files = builtins.listToAttrs (map (cmd: {
    name = ".claude/commands/${cmd}.md";
    value = {
      source = "${commandsDir}/${cmd}.md";
    };
  }) communityCommands);
}
