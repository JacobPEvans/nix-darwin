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

let
  cfg = config.programs.claude;
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
      ".claude/.keep".text = "# Managed by Nix - programs.claude module\n";
      ".claude/plugins/.keep".text = "# Plugin registry managed by Nix\n";
    };

    # Activation script for dynamic values (timestamps, validation)
    home.activation.claudeSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Update timestamps in registry files if needed
      REGISTRY="${config.home.homeDirectory}/.claude/plugins/known_marketplaces.json"
      if [ -f "$REGISTRY" ] && grep -q "@ACTIVATION_TIME@" "$REGISTRY" 2>/dev/null; then
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
        ${pkgs.gnused}/bin/sed -i "s/@ACTIVATION_TIME@/$TIMESTAMP/g" "$REGISTRY"
      fi

      # Create local marketplace directory for hybrid mode
      ${lib.optionalString cfg.plugins.allowRuntimeInstall ''
        mkdir -p "${config.home.homeDirectory}/.claude/plugins/marketplaces/local"
      ''}

      # Optional: Validate plugin structure
      ${lib.optionalString (cfg.features.experimental.pluginValidation or false) ''
        echo "Validating Claude plugin configuration..."
        # Add validation logic here
      ''}
    '';
  };
}
