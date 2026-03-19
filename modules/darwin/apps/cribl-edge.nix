# Cribl Edge Service Management
#
# Manages the Cribl Edge LaunchDaemon declaratively so it survives .pkg upgrades.
# The .pkg installer drops its own plist at /Library/LaunchDaemons/io.cribl.plist
# which gets overwritten on every upgrade — this module removes it and replaces it
# with a Nix-managed service definition.
#
# Cribl Edge itself is installed externally via .pkg (not in any package manager).
# This module manages: LaunchDaemon lifecycle, ACL-based file permissions.
# No root execution. No FDA — ACLs only for monitored paths.

{ lib, config, ... }:

let
  cfg = config.programs.cribl-edge;
in
{
  options.programs.cribl-edge = {
    enable = lib.mkEnableOption "Cribl Edge service management";

    installPath = lib.mkOption {
      type = lib.types.path;
      default = /opt/cribl;
      description = "Installation path for Cribl Edge (set by .pkg installer).";
    };

    acls = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Paths to grant the cribl user read ACL access to.";
      example = [
        "/var/log"
        "/Users/<username>/.claude/logs"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Remove .pkg-installed plist — Nix manages the service declaratively
    system.activationScripts.preActivation.text = lib.mkAfter ''
      if [ -f /Library/LaunchDaemons/io.cribl.plist ]; then
        /bin/launchctl bootout system/io.cribl 2>/dev/null || true
        rm -f /Library/LaunchDaemons/io.cribl.plist
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Removed .pkg-installed Cribl plist (Nix manages this service)"
      fi
    '';

    system.activationScripts.postActivation.text = lib.mkAfter ''
      if [ ! -d "${toString cfg.installPath}/bin" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] Cribl Edge not found at ${toString cfg.installPath}"
        echo "  Install via .pkg from https://cribl.io/download/ or Cribl Cloud enrollment"
      fi

      ${lib.optionalString (cfg.acls != [ ]) ''
        ${lib.concatMapStringsSep "\n" (path: ''
          if [ -e "${path}" ]; then
            /bin/chmod +a "cribl allow read,readattr,readextattr,readsecurity,list,search" "${path}" 2>/dev/null || true
          fi
        '') cfg.acls}
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Applied Cribl Edge ACLs to ${toString (builtins.length cfg.acls)} path(s)"
      ''}
    '';

    launchd.daemons.cribl-edge = {
      serviceConfig = {
        Label = "com.nix-darwin.cribl-edge";
        ProgramArguments = [
          "${toString cfg.installPath}/bin/cribl"
          "server"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        UserName = "cribl";
        GroupName = "cribl";
        WorkingDirectory = toString cfg.installPath;
        StandardOutPath = "${toString cfg.installPath}/log/cribl-stdout.log";
        StandardErrorPath = "${toString cfg.installPath}/log/cribl-stderr.log";
        EnvironmentVariables = {
          CRIBL_HOME = toString cfg.installPath;
        };
      };
    };
  };
}
