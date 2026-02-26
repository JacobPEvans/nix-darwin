# Claude Code Settings
#
# Generates ~/.claude/settings.json with all configuration.
# Merges plugin marketplaces, permissions, MCP servers, etc.
#
# NOTE: Uses toClaudeMarketplaceFormat from lib/claude-registry.nix as
# SINGLE SOURCE OF TRUTH for marketplace format transformation.
#
# VALIDATION: Environment variable names are validated at build time against
# POSIX convention (^[A-Z_][A-Z0-9_]*$). Full JSON Schema validation against
# https://json.schemastore.org/claude-code-settings.json is available via
# `nix flake check` but requires network access.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.claude;
  homeDir = config.home.homeDirectory;

  # Import the single source of truth for marketplace formatting
  claudeRegistry = import ../../../../lib/claude-registry.nix { inherit lib; }; # lastUpdated not needed here
  inherit (claudeRegistry) toClaudeMarketplaceFormat;

  # Build the env attribute (merge user env vars with API_KEY_HELPER if enabled)
  # Environment variable names must match POSIX convention: ^[A-Z_][A-Z0-9_]*$
  envAttrs =
    cfg.settings.env
    // lib.optionalAttrs cfg.apiKeyHelper.enable {
      API_KEY_HELPER = "${homeDir}/${cfg.apiKeyHelper.scriptPath}";
    };

  # Validate POSIX environment variable names
  # POSIX requires: starts with letter or underscore, followed by letters, digits, or underscores
  # We enforce uppercase for convention: ^[A-Z_][A-Z0-9_]*$
  isValidEnvVarName = name: builtins.match "^[A-Z_][A-Z0-9_]*$" name != null;
  invalidEnvVars = lib.filterAttrs (name: _: !isValidEnvVarName name) envAttrs;

  # Build the settings object
  settings = {
    "$schema" = cfg.settings.schemaUrl;
    inherit (cfg.settings) alwaysThinkingEnabled cleanupPeriodDays;
    inherit (cfg)
      autoUpdatesChannel
      teammateMode
      showTurnDuration
      effortLevel
      ;
  }
  // lib.optionalAttrs (cfg.attribution != { }) { inherit (cfg) attribution; }
  // {

    # Permissions
    permissions = {
      inherit (cfg.settings.permissions) allow deny ask;
      inherit (cfg.settings) additionalDirectories;
    };

    # Plugin configuration
    # Uses toClaudeMarketplaceFormat (single source of truth from lib/claude-registry.nix)
    extraKnownMarketplaces = lib.mapAttrs toClaudeMarketplaceFormat cfg.plugins.marketplaces;

    enabledPlugins = cfg.plugins.enabled;

    # NOTE: MCP servers are NOT configured in settings.json
    # Claude Code reads MCP servers from ~/.claude.json (user scope) or .mcp.json (project scope)
    # Use `claude mcp add --scope user` to add servers, or run with d-claude alias for Doppler secrets
    # The mcpServers option is kept for documentation but not output here

    # Environment variables (user-defined + apiKeyHelper if enabled)
  }
  // lib.optionalAttrs (cfg.model != null) { inherit (cfg) model; }
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
  )

  # Sandbox configuration (Dec 2025 feature)
  # Only include when sandbox is actually enabled to avoid confusing disabled state with configuration
  // lib.optionalAttrs cfg.settings.sandbox.enabled {
    sandbox = {
      inherit (cfg.settings.sandbox) enabled autoAllowBashIfSandboxed;
    }
    // lib.optionalAttrs (cfg.settings.sandbox.excludedCommands != [ ]) {
      inherit (cfg.settings.sandbox) excludedCommands;
    };
  };

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

  # Hook scripts generator
  # Converts hook options to executable scripts in ~/.claude/hooks/
  hookFiles =
    let
      # Map of hook names to their filenames
      hookMapping = {
        preToolUse = "pre-tool-use.sh";
        postToolUse = "post-tool-use.sh";
        userPromptSubmit = "user-prompt-submit.sh";
        stop = "stop.sh";
        subagentStop = "subagent-stop.sh";
        sessionStart = "session-start.sh";
        sessionEnd = "session-end.sh";
      };

      # Generate a single hook file attribute
      mkHookFile =
        _hookName: fileName: hookValue:
        if hookValue == null then
          { }
        else if builtins.isPath hookValue then
          {
            ".claude/hooks/${fileName}" = {
              source = hookValue;
              executable = true;
            };
          }
        else
          {
            ".claude/hooks/${fileName}" = {
              text = hookValue;
              executable = true;
            };
          };

      # Generate all hook files
      allHookFiles = lib.mapAttrs' (
        hookName: fileName: lib.nameValuePair hookName (mkHookFile hookName fileName cfg.hooks.${hookName})
      ) hookMapping;

      # Merge all non-null hook files into a single attrset
      # Note: lib.mkMerge is for option values, not attrsets. Use foldl' for regular merging.
      mergedHookFiles = lib.foldl' (a: b: a // b) { } (builtins.attrValues allHookFiles);
    in
    mergedHookFiles;

in
{
  config = lib.mkIf cfg.enable {
    # Merge remoteControlAtStartup into ~/.claude.json (global config) at activation time.
    # This key lives in the global config file, not settings.json, so home.file cannot be
    # used directly (the file is runtime-mutable). jq merges only this key idempotently.
    home.activation = lib.mkIf (cfg.remoteControlAtStartup != null) {
      claudeRemoteControlAtStartup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        CLAUDE_JSON="$HOME/.claude.json"
        RC_VALUE=${lib.boolToString cfg.remoteControlAtStartup}
        if [ -f "$CLAUDE_JSON" ]; then
          TMP=$(mktemp)
          ${pkgs.jq}/bin/jq --argjson v "$RC_VALUE" '.remoteControlAtStartup = $v' \
            "$CLAUDE_JSON" > "$TMP" && mv "$TMP" "$CLAUDE_JSON"
        else
          printf '{"remoteControlAtStartup": %s}\n' "$RC_VALUE" > "$CLAUDE_JSON"
        fi
      '';
    };

    # Validate environment variable names before generating settings.json
    assertions = [
      {
        assertion = invalidEnvVars == { };
        message = ''
          Invalid environment variable names in programs.claude.settings.env:
            ${lib.concatStringsSep ", " (builtins.attrNames invalidEnvVars)}

          Environment variable names must match POSIX convention: ^[A-Z_][A-Z0-9_]*$
          (uppercase letters, digits, and underscores only; must start with letter or underscore)
        '';
      }
    ];

    home.file = {
      ".claude/settings.json" = {
        source = settingsJson;
        force = true;
      };
    }
    // statusLineScript
    // hookFiles;

  };
}
