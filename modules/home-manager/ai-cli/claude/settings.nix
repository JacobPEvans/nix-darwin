# Claude Code Settings
#
# Generates ~/.claude/settings.json with all configuration.
# Merges plugin marketplaces, permissions, MCP servers, etc.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.claude;
  homeDir = config.home.homeDirectory;

  # Build the env attribute (merge user env vars with apiKeyHelper if enabled)
  envAttrs =
    cfg.settings.env
    // lib.optionalAttrs cfg.apiKeyHelper.enable {
      apiKeyHelper = "${homeDir}/${cfg.apiKeyHelper.scriptPath}";
    };

  # Build the settings object
  settings = {
    "$schema" = cfg.settings.schemaUrl;
    inherit (cfg.settings) alwaysThinkingEnabled cleanupPeriodDays;

    # Permissions
    permissions = {
      inherit (cfg.settings.permissions) allow deny ask;
      inherit (cfg.settings) additionalDirectories;
    };

    # Plugin configuration
    # Claude expects: { source: { source: "github", repo: "owner/repo" } }
    # For non-github sources, use url instead
    extraKnownMarketplaces = lib.mapAttrs (name: m: {
      source =
        if m.source.type == "github" || m.source.type == "git" then
          {
            source = "github";
            repo = name; # The key itself is "owner/repo" format
          }
        else
          {
            source = m.source.type;
            inherit (m.source) url;
          };
    }) cfg.plugins.marketplaces;

    enabledPlugins = cfg.plugins.enabled;

    # MCP servers (filtered out disabled ones)
    mcpServers = lib.mapAttrs (
      _: s:
      {
        inherit (s) command args;
      }
      // lib.optionalAttrs (s.env != { }) { inherit (s) env; }
    ) (lib.filterAttrs (_: s: !(s.disabled or false)) cfg.mcpServers);

    # Environment variables (user-defined + apiKeyHelper if enabled)
  }
  // lib.optionalAttrs (envAttrs != { }) { env = envAttrs; }

  # Status line (only include if we have valid configuration)
  # Include when: enhanced mode with package, OR custom script (with enhanced disabled)
  # Do NOT include empty statusLine object (breaks Claude Code schema)
  // (
    let
      # Extract duplicate condition to avoid divergence between outer and inner checks
      hasEnhancedStatusLine = cfg.statusLine.enhanced.enable && cfg.statusLine.enhanced.package != null;
      hasCustomScript = cfg.statusLine.script != null && !cfg.statusLine.enhanced.enable;
    in
    lib.optionalAttrs (cfg.statusLine.enable && (hasEnhancedStatusLine || hasCustomScript)) {
      statusLine = {
        type = "command";
        command =
          if
            hasEnhancedStatusLine
          # Reference package built by statusline.nix (single source of truth)
          then
            "${cfg.statusLine.enhanced.package}/bin/claude-code-statusline"
          else
            "${homeDir}/.claude/statusline-command.sh";
      };
    }
  );

  # Pretty-print JSON
  settingsJson =
    pkgs.runCommand "claude-settings.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
        passAsFile = [ "json" ];
        json = builtins.toJSON settings;
      }
      ''
        jq '.' "$jsonPath" > $out
      '';

  # Status line script (if using simple script mode)
  statusLineScript =
    lib.optionalAttrs
      (cfg.statusLine.enable && cfg.statusLine.script != null && !cfg.statusLine.enhanced.enable)
      {
        ".claude/statusline-command.sh" = {
          text = cfg.statusLine.script;
          executable = true;
        };
      };

in
{
  config = lib.mkIf cfg.enable {
    home.file = {
      ".claude/settings.json".source = settingsJson;
    }
    // statusLineScript;
  };
}
