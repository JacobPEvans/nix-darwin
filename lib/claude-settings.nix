# Pure Claude Code Settings Generator
#
# Generates the settings attrset without any derivations or platform-specific code.
# Used by:
#   - modules/home-manager/ai-cli/claude.nix (for deployment with jq pretty-printing)
#   - flake.nix CI output (for cross-platform schema validation)
#
# This separation enables pure Nix evaluation for CI while keeping
# pretty-printed JSON for local deployment.

{ homeDir
, schemaUrl
, permissions  # { allow, deny, ask }
, plugins      # { marketplaces, enabledPlugins }
}:

{
  # JSON Schema for IDE IntelliSense and validation
  "$schema" = schemaUrl;

  # Enable extended thinking mode
  alwaysThinkingEnabled = true;

  # Plugin marketplace configuration
  extraKnownMarketplaces = plugins.marketplaces;

  # Enabled plugins from marketplaces
  enabledPlugins = plugins.enabledPlugins;

  # Permissions from ai-assistant-instructions
  permissions = {
    inherit (permissions) allow deny ask;

    # Directory-level read access
    additionalDirectories = [
      "~/"              # Full home directory access
      "~/.claude/"      # Claude configuration
      "~/.config/"      # XDG config directory
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
