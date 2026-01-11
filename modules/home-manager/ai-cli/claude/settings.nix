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

    # Permissions
    permissions = {
      inherit (cfg.settings.permissions) allow deny ask;
      inherit (cfg.settings) additionalDirectories;
    };

    # Plugin configuration
    # Uses toClaudeMarketplaceFormat (single source of truth from lib/claude-registry.nix)
    extraKnownMarketplaces = lib.mapAttrs toClaudeMarketplaceFormat cfg.plugins.marketplaces;

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

in
{
  config = lib.mkIf cfg.enable {
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
      ".claude/settings.json".source = settingsJson;
    }
    // statusLineScript;

    # Cleanup activation script: Remove blocking regular files before symlink creation
    # This handles the case where settings.json exists as a regular file (e.g., created by Claude Code)
    # which would prevent home-manager from creating the Nix-managed symlink
    #
    # Note: Uses .backup suffix (same as home-manager's backup mechanism) for consistency.
    # Timestamped backups would create accumulating files; single .backup is cleaner.
    # Log format: YYYY-MM-DD HH:MM:SS [LOG_LEVEL] message
    home.activation.cleanupClaudeSettings = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      SETTINGS="${homeDir}/.claude/settings.json"
      if [ -e "$SETTINGS" ] && [ ! -L "$SETTINGS" ]; then
        BACKUP="$SETTINGS.backup"
        if ! $DRY_RUN_CMD mv "$SETTINGS" "$BACKUP"; then
          echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] Failed to back up existing settings.json from $SETTINGS to $BACKUP" >&2
          exit 1
        fi
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Backed up existing settings.json to $BACKUP" >&2
      fi

      # Also clean up broken statusline symlink
      OLD_STATUSLINE="${homeDir}/.claude/statusline/Config.toml"
      if [ -L "$OLD_STATUSLINE" ] && [ ! -e "$OLD_STATUSLINE" ]; then
        if ! $DRY_RUN_CMD rm "$OLD_STATUSLINE"; then
          echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] Failed to remove broken statusline symlink at $OLD_STATUSLINE" >&2
          exit 1
        fi
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Removed broken statusline symlink" >&2
      fi
    '';
  };
}
