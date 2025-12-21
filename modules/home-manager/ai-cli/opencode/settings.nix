# OpenCode Settings Generation
#
# Generates OpenCode configuration file from declarative options.
# Integrates shared permissions when useShared is enabled.
{
  config,
  lib,
  pkgs,
  ai-assistant-instructions ? null,
  ...
}:

let
  cfg = config.programs.opencode;

  # Read shared permissions from ai-assistant-instructions if available
  readPermissionsJson =
    path:
    let
      json = builtins.fromJSON (builtins.readFile path);
    in
    if builtins.isAttrs json && json ? permissions then
      json.permissions
    else
      builtins.throw "Invalid permissions JSON at ${path}: must contain a 'permissions' key";

  # Get shared permissions when useShared is enabled
  sharedPermissions =
    if cfg.permissions.useShared && ai-assistant-instructions != null then
      {
        allow = readPermissionsJson "${ai-assistant-instructions}/.claude/permissions/allow.json";
        deny = readPermissionsJson "${ai-assistant-instructions}/.claude/permissions/deny.json";
        ask = readPermissionsJson "${ai-assistant-instructions}/.claude/permissions/ask.json";
      }
    else
      {
        allow = [ ];
        deny = [ ];
        ask = [ ];
      };

  # Merge shared and OpenCode-specific permissions
  permissions = {
    allow = sharedPermissions.allow ++ cfg.permissions.allow;
    deny = sharedPermissions.deny ++ cfg.permissions.deny;
    ask = sharedPermissions.ask ++ cfg.permissions.ask;
  };

  # Filter enabled providers
  enabledProviders = lib.filterAttrs (_name: provider: provider.enabled) cfg.settings.providers;

  # Generate OpenCode settings object
  opencodeSettings = {
    "$schema" = cfg.schemaUrl;

    inherit (cfg.settings) theme defaultModel;

    # Provider configurations
    providers = lib.mapAttrs (
      _name: provider:
      {
        inherit (provider) enabled models;
        # Only include apiKey if set (null means read from env)
      }
      // lib.optionalAttrs (provider.apiKey != null) {
        inherit (provider) apiKey;
      }
    ) enabledProviders;

    # Permissions
    inherit permissions;

    # Environment variables
    inherit (cfg.settings) env;

    # Plugin configuration (placeholder for Issue #140)
    plugins =
      lib.optionalAttrs cfg.plugins.oh-my-opencode.enable {
        "oh-my-opencode" = {
          enabled = true;
        };
      }
      // lib.mapAttrs (_name: enabled: { inherit enabled; }) cfg.plugins.enabled;
  };

  # Pretty-print JSON using jq
  opencodeSettingsJson =
    pkgs.runCommand "opencode-settings.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
        json = builtins.toJSON opencodeSettings;
        passAsFile = [ "json" ];
      }
      ''
        jq '.' "$jsonPath" > $out
      '';

in
{
  config = lib.mkIf cfg.enable {
    home.file = {
      # OpenCode settings file
      "${cfg.configDir}/settings.json".source = opencodeSettingsJson;

      # Keep marker for config directory
      "${cfg.configDir}/.keep".text = ''
        # Managed by Nix - programs.opencode module
      '';
    };
  };
}
