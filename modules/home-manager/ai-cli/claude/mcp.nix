# Claude Code MCP Server Configuration
#
# MCP servers are configured in settings.json (handled by settings.nix).
# This file can be extended for MCP-specific functionality like:
# - Server health checks
# - Auto-discovery
# - Server-specific configuration files
{ config, lib, ... }:

let
  cfg = config.programs.claude;
in {
  # MCP servers are currently handled entirely in settings.nix
  # This module exists for future MCP-specific extensions
  config = lib.mkIf cfg.enable {
    # Placeholder for future MCP functionality
    # e.g., generating per-server config files, health check scripts
  };
}
