# Claude Code Settings
#
# Generates ~/.claude/settings.json with all configuration.
# Merges plugin marketplaces, permissions, MCP servers, etc.
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.claude;
  homeDir = config.home.homeDirectory;

  # Build the settings object
  settings = {
    "$schema" = cfg.settings.schemaUrl;
    alwaysThinkingEnabled = cfg.settings.alwaysThinkingEnabled;

    # Permissions
    permissions = {
      allow = cfg.settings.permissions.allow;
      deny = cfg.settings.permissions.deny;
      ask = cfg.settings.permissions.ask;
      additionalDirectories = cfg.settings.additionalDirectories;
    };

    # Plugin configuration
    extraKnownMarketplaces = lib.mapAttrs (_: m: {
      source = { source = m.source.type; url = m.source.url; };
    }) cfg.plugins.marketplaces;

    enabledPlugins = cfg.plugins.enabled;

    # MCP servers (filtered out disabled ones)
    mcpServers = lib.mapAttrs (_: s: {
      command = s.command;
      args = s.args;
    } // lib.optionalAttrs (s.env != {}) { env = s.env; })
      (lib.filterAttrs (_: s: !(s.disabled or false)) cfg.mcpServers);

    # Status line (if enabled)
  } // lib.optionalAttrs cfg.statusLine.enable {
    statusLine = if cfg.statusLine.enhanced.enable && cfg.statusLine.enhanced.source != null then {
      type = "command";
      # Reference statusline binary (built in statusline.nix, deduped by Nix)
      command = let
        statuslinePkg = pkgs.stdenvNoCC.mkDerivation {
          pname = "claude-code-statusline";
          version = "2.1.0";
          src = cfg.statusLine.enhanced.source;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          installPhase = ''
            mkdir -p $out/share/claude-code-statusline $out/bin
            cp -r . $out/share/claude-code-statusline/
            makeWrapper $out/share/claude-code-statusline/statusline.sh $out/bin/claude-code-statusline \
              --prefix PATH : ${lib.makeBinPath [ pkgs.bash pkgs.jq pkgs.git pkgs.coreutils ]}
            chmod +x $out/bin/claude-code-statusline
          '';
        };
      in "${statuslinePkg}/bin/claude-code-statusline";
    } else if cfg.statusLine.script != null then {
      type = "command";
      command = "${homeDir}/.claude/statusline-command.sh";
    } else { };
  };

  # Pretty-print JSON
  settingsJson = pkgs.runCommand "claude-settings.json" {
    nativeBuildInputs = [ pkgs.jq ];
    passAsFile = [ "json" ];
    json = builtins.toJSON settings;
  } ''
    jq '.' "$jsonPath" > $out
  '';

  # Status line script (if using simple script mode)
  statusLineScript = lib.optionalAttrs
    (cfg.statusLine.enable && cfg.statusLine.script != null && !cfg.statusLine.enhanced.enable)
    {
      ".claude/statusline-command.sh" = {
        text = cfg.statusLine.script;
        executable = true;
      };
    };

in {
  config = lib.mkIf cfg.enable {
    home.file = {
      ".claude/settings.json".source = settingsJson;
    } // statusLineScript;
  };
}
