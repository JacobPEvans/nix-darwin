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
#
# Note: Disabling this module does not automatically remove ACLs from previously
# configured paths. Run `/bin/chmod -a "cribl allow ..." <path>` manually if needed.

{ lib, config, ... }:

let
  cfg = config.programs.cribl-edge;
  path = cfg.installPath;
  user = "cribl";
  group = "cribl";
  aclPerms = "${user} allow read,readattr,readextattr,readsecurity,list,search";
  ts = "$(date '+%Y-%m-%d %H:%M:%S')";
in
{
  options.programs.cribl-edge = {
    enable = lib.mkEnableOption "Cribl Edge service management";

    installPath = lib.mkOption {
      type = lib.types.str;
      default = "/opt/cribl";
      description = "Installation path for Cribl Edge (set by .pkg installer).";
    };

    acls = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Paths to grant the cribl user read ACL access to.";
      example = [
        "/var/log"
        "/var/audit"
        "/Library/Logs"
        "/Library/Logs/DiagnosticReports"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Remove .pkg-installed plist — Nix manages the service declaratively
    system.activationScripts.preActivation.text = lib.mkAfter ''
      if [ -f /Library/LaunchDaemons/io.cribl.plist ]; then
        /bin/launchctl bootout system/io.cribl 2>/dev/null || true
        rm -f /Library/LaunchDaemons/io.cribl.plist
        echo "${ts} [INFO] Removed .pkg-installed Cribl plist (Nix manages this service)"
      fi
    '';

    system.activationScripts.postActivation.text = lib.mkAfter ''
      if [ ! -d "${path}/bin" ]; then
        echo "${ts} [WARN] Cribl Edge not found at ${path}"
        echo "  Install via .pkg from https://cribl.io/download/ or Cribl Cloud enrollment"
      else
        # The .pkg installer creates everything as root:wheel but the LaunchDaemon
        # runs as ${user}:${group}. Only chown if ownership has drifted.
        if [ "$(/usr/bin/stat -f '%Su' "${path}")" != "${user}" ]; then
          /usr/sbin/chown -R ${user}:${group} "${path}"
          echo "${ts} [INFO] Fixed Cribl Edge directory ownership → ${user}:${group}"
        fi
      fi

      ${lib.optionalString (cfg.acls != [ ]) ''
        # Remove-then-add ensures idempotency: prevents duplicate ACEs across rebuilds
        _acl_applied=0
        ${lib.concatMapStringsSep "\n" (p: ''
          if [ -e "${p}" ]; then
            /bin/chmod -a "${aclPerms}" "${p}" 2>/dev/null || true
            /bin/chmod +a "${aclPerms}" "${p}" 2>&1 || echo "${ts} [WARN] Failed to set ACL on ${p}"
            _acl_applied=$((_acl_applied + 1))
          fi
        '') cfg.acls}
        echo "${ts} [INFO] Applied Cribl Edge ACLs to $_acl_applied of ${toString (builtins.length cfg.acls)} path(s)"
      ''}
    '';

    launchd.daemons.cribl-edge = {
      serviceConfig = {
        Label = "com.nix-darwin.cribl-edge";
        ProgramArguments = [
          "${path}/bin/cribl"
          "server"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        UserName = user;
        GroupName = group;
        WorkingDirectory = path;
        StandardOutPath = "${path}/log/cribl-stdout.log";
        StandardErrorPath = "${path}/log/cribl-stderr.log";
        EnvironmentVariables = {
          CRIBL_HOME = path;
        };
      };
    };
  };
}
