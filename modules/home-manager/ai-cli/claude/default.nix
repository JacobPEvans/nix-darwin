# Unified Claude Code Configuration Module
#
# This module consolidates all Claude Code configuration into a single
# declarative interface: plugins, commands, agents, skills, hooks, MCP servers.
#
# Features:
# - Declarative plugin management via flake inputs
# - Hybrid mode: Nix-managed baseline + runtime /plugin install
# - Cross-platform: Works on Darwin, NixOS, standalone home-manager
# - Generates settings.json, known_marketplaces.json, installed_plugins.json
#
# Usage:
#   programs.claude = {
#     enable = true;
#     plugins.enabled = { "commit-commands@anthropics/claude-code" = true; };
#   };
{ config, lib, pkgs, ... }:

let cfg = config.programs.claude;
in {
  imports = [
    ./options.nix
    ./registry.nix
    ./plugins.nix
    ./components.nix
    ./settings.nix
    ./statusline.nix
    ./mcp.nix
  ];

  config = lib.mkIf cfg.enable {
    # Ensure ~/.claude directory structure exists
    # Individual sub-modules populate these directories
    home.file = {
      ".claude/.keep".text = ''
        # Managed by Nix - programs.claude module
      '';
      ".claude/plugins/.keep".text = ''
        # Plugin registry managed by Nix
      '';
    };

    # Activation script for directory setup
    home.activation.claudeSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Create local marketplace directory for hybrid mode
      ${lib.optionalString cfg.plugins.allowRuntimeInstall ''
        mkdir -p "${config.home.homeDirectory}/.claude/plugins/marketplaces/local"
      ''}
    '';
  };
}
