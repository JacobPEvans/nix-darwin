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
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.claude;
in
{
  imports = [
    ./options.nix
    ./registry.nix
    ./plugins.nix
    ./components.nix
    ./settings.nix
    ./statusline.nix
    ./statusline # New modular statusline (Issue #80)
    ./mcp.nix
    ./auto-claude.nix
  ];

  config = lib.mkIf cfg.enable {
    # Validate secretId is provided when apiKeyHelper is enabled
    assertions = [
      {
        assertion = !cfg.apiKeyHelper.enable || (cfg.apiKeyHelper.secretId or "") != "";
        message = ''
          programs.claude.apiKeyHelper.enable is true but secretId is not set.
          Please provide the Bitwarden secret ID:
            programs.claude.apiKeyHelper.secretId = "your-secret-id";
        '';
      }
    ];

    # Ensure ~/.claude directory structure exists
    # Individual sub-modules populate these directories
    home.file = {
      ".claude/.keep".text = ''
        # Managed by Nix - programs.claude module
      '';
      ".claude/plugins/.keep".text = ''
        # Plugin registry managed by Nix
      '';
    }
    // lib.optionalAttrs cfg.apiKeyHelper.enable {
      # API Key Helper script for headless authentication
      "${cfg.apiKeyHelper.scriptPath}" = {
        source = pkgs.replaceVars ./get-api-key.sh {
          inherit (cfg.apiKeyHelper) keychainService;
          bwsSecretId = cfg.apiKeyHelper.secretId;
        };
        executable = true;
      };
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
