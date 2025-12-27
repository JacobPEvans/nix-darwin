# Pure Claude Code Settings Generator
#
# Generates the settings attrset without any derivations or platform-specific code.
# Used by:
#   - modules/home-manager/ai-cli/claude.nix (for deployment with jq pretty-printing)
#   - flake.nix CI output (for cross-platform schema validation)
#
# This separation enables pure Nix evaluation for CI while keeping
# pretty-printed JSON for local deployment.

{
  lib ? import <nixpkgs/lib>,
  homeDir,
  schemaUrl,
  permissions, # { allow, deny, ask }
  plugins, # { marketplaces, enabledPlugins }
}:

let
  # Transform marketplace config to Claude's expected format
  # Claude expects: { source: { source: "github", repo: "owner/repo" } }
  # Nix config has: { source: { type: "github", url: "..." } }
  toClaudeMarketplaceFormat = name: m: {
    source =
      if m.source.type == "github" || m.source.type == "git" then
        {
          source = "github";
          repo = name; # "owner/repo" format (the key itself)
        }
      else
        {
          source = m.source.type;
          inherit (m.source) url;
        };
  };
in
{
  # JSON Schema for IDE IntelliSense and validation
  "$schema" = schemaUrl;

  # Enable extended thinking mode
  alwaysThinkingEnabled = true;

  # Plugin marketplace configuration - transformed to Claude's expected format
  extraKnownMarketplaces = lib.mapAttrs toClaudeMarketplaceFormat plugins.marketplaces;

  # Enabled plugins from marketplaces
  inherit (plugins) enabledPlugins;

  # Permissions from ai-assistant-instructions
  permissions = {
    inherit (permissions) allow deny ask;

    # Directory-level read access
    additionalDirectories = [
      "~/" # Full home directory access
      "~/.claude/" # Claude configuration
      "~/.config/" # XDG config directory
    ];
  };

  # Status line configuration
  statusLine = {
    type = "command";
    command = "${homeDir}/.claude/statusline-command.sh";
  };

  # MCP Servers
  mcpServers = {
    bitwarden = {
      command = "${homeDir}/.npm-packages/bin/mcp-server-bitwarden";
      args = [ ];
    };
  };
}
