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
    ./auto-claude-reporting.nix
    ./menubar.nix
  ];

  config = lib.mkIf cfg.enable {
    # Note: apiKeyHelper now reads config from ~/.config/bws/.env
    # The Python helper (bws_helper.py) will give clear errors if config is missing

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
      # Configuration now comes from ~/.config/bws/.env (not Nix options)
      "${cfg.apiKeyHelper.scriptPath}" = {
        source = ./get-api-key.py; # Python script using bws_helper
        executable = true;
      };
    };

    # Activation scripts for directory and config setup
    home.activation = {
      # Claude setup - create local marketplace directory with marketplace.json
      claudeSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Create local marketplace directory for hybrid mode
        ${lib.optionalString cfg.plugins.allowRuntimeInstall ''
                    MARKETPLACE_DIR="${config.home.homeDirectory}/.claude/plugins/marketplaces/local"
                    mkdir -p "$MARKETPLACE_DIR/.claude-plugin"

                    # Create marketplace.json if it doesn't exist
                    if [ ! -f "$MARKETPLACE_DIR/.claude-plugin/marketplace.json" ]; then
                      $DRY_RUN_CMD cat > "$MARKETPLACE_DIR/.claude-plugin/marketplace.json" <<'EOF'
          {"id":"local","plugins":[]}
          EOF
                    fi
        ''}
      '';

      # WakaTime config file - created once with placeholder API key
      # User must edit ~/.wakatime.cfg and replace waka_YOUR-API-KEY-HERE with real key
      # See: https://wakatime.com/settings/account
      wakatimeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                WAKATIME_CFG="${config.home.homeDirectory}/.wakatime.cfg"

                if [ ! -f "$WAKATIME_CFG" ]; then
                  $DRY_RUN_CMD cat > "$WAKATIME_CFG" <<'EOF'
        [settings]
        api_key = waka_YOUR-API-KEY-HERE
        EOF
                  $DRY_RUN_CMD chmod 600 "$WAKATIME_CFG"
                  echo "Created $WAKATIME_CFG with placeholder API key"
                  echo "Edit this file and replace waka_YOUR-API-KEY-HERE with your real key"
                  echo "Get your API key from: https://wakatime.com/settings/account"
                else
                  echo "WakaTime config already exists at $WAKATIME_CFG (not overwriting)"
                fi
      '';
    };
  };
}
