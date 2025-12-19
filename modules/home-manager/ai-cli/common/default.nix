# AI CLI Common Module
#
# Provides unified permission definitions and formatters for all AI CLI tools.
# This is the single source of truth for command permissions.
#
# USAGE:
#   let
#     aiCommon = import ./common { inherit lib config; };
#     geminiCoreTools = aiCommon.formatters.gemini.formatCoreTools aiCommon.permissions;
#   in { ... }
#
# EXPORTS:
# - permissions: Tool-agnostic command definitions
# - formatters: Tool-specific formatting functions

{ lib, config, ... }:

{
  # Unified permission definitions
  permissions = import ./permissions.nix { inherit lib config; };

  # Tool-specific formatters
  formatters = import ./formatters.nix { inherit lib; };
}
