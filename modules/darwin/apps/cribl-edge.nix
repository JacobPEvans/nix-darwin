# Cribl Edge Service Management
#
# Manages the Cribl Edge LaunchDaemon declaratively so it survives .pkg upgrades.
# The .pkg installer drops its own plist at /Library/LaunchDaemons/io.cribl.plist
# which gets overwritten on every upgrade — this module removes it and replaces it
# with a Nix-managed service definition.
#
# Installation uses Cribl Cloud's official install-edge.sh endpoint, which handles
# binary download, .pkg installation, and fleet enrollment in one step.
# Cribl Cloud manages all runtime configuration after enrollment.
#
# Secrets are provided via sops-nix (modules/darwin/sops.nix), which decrypts
# age-encrypted credentials to a root-only KEY=value file at activation time.
# This avoids bridging root activation into the user Keychain.
#
# Service runs as root (temporary — revert serviceUser/serviceGroup to cribl:cribl when ready).

{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.programs.cribl-edge;
  ts = "$(date '+%Y-%m-%d %H:%M:%S')";

  deployPackScript = pkgs.writeShellApplication {
    name = "cribl-deploy-pack";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./scripts/cribl-edge-deploy-pack.sh;
  };

  startScript = pkgs.writeShellApplication {
    name = "cribl-edge-start";
    runtimeInputs = [ ];
    text = ''
      set -a
      # Source secrets to get CRIBL_ORG_ID, CRIBL_WORKSPACE_ID, CRIBL_TOKEN
      if [ -r "${cfg.cloud.secretsFile}" ]; then
        # shellcheck disable=SC1090,SC1091
        source "${cfg.cloud.secretsFile}"
      else
        echo "${ts} [ERROR] Cribl secrets file not readable: ${cfg.cloud.secretsFile}" >&2
        exit 1
      fi
      set +a

      export CRIBL_VOLUME_DIR="${cfg.dataDir}"
      export CRIBL_HOME="${cfg.package}/opt/cribl"

      mkdir -p "$CRIBL_VOLUME_DIR"

      # Enroll if instance.yml doesn't exist
      if [ ! -f "$CRIBL_VOLUME_DIR/local/_system/instance.yml" ] && [ ! -f "$CRIBL_VOLUME_DIR/local/edge/instance.yml" ]; then
        echo "${ts} [INFO] Enrolling Cribl Edge to cloud..."
        if [ -z "''${CRIBL_WORKSPACE_ID:-}" ] || [ -z "''${CRIBL_ORG_ID:-}" ] || [ -z "''${CRIBL_TOKEN:-}" ]; then
           echo "${ts} [ERROR] Missing required Cribl secrets for enrollment." >&2
           exit 1
        fi
        
        # Suppress warnings about running as root when binaries are root
        ${cfg.package}/opt/cribl/bin/cribl mode-managed-edge \
          -H "''${CRIBL_WORKSPACE_ID}-''${CRIBL_ORG_ID}.cribl.cloud" \
          -p 443 -u "$CRIBL_TOKEN" -g "${cfg.cloud.group}" -S true || true
      fi

      # Start server
      exec ${cfg.package}/opt/cribl/bin/cribl server
    '';
  };
in
{
  options.programs.cribl-edge = {
    enable = lib.mkEnableOption "Cribl Edge service management";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../../packages/cribl-edge.nix { };
      description = "The Cribl Edge package to use.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/cribl-data";
      description = "Writable volume directory for Cribl state and configuration.";
    };

    serviceUser = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User to run the Cribl Edge service as.";
    };

    serviceGroup = lib.mkOption {
      type = lib.types.str;
      default = "wheel";
      description = "Group to run the Cribl Edge service as.";
    };

    cloud = {
      secretsFile = lib.mkOption {
        type = lib.types.str;
        description = ''
          Path to a root-readable KEY=value file containing CRIBL_ORG_ID,
          CRIBL_WORKSPACE_ID, and CRIBL_TOKEN. Use the sops-nix rendered
          template: config.sops.templates."cribl-edge.env".path
        '';
        example = "/run/secrets/rendered/cribl-edge.env";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "default_fleet";
        description = "Fleet group name.";
      };
    };

    packs = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = ''
        Cribl Edge packs to deploy declaratively.
        Key = pack name, value = derivation containing pack files.
        Use fetchzip with extension = "tar.gz" for .crbl files.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Run pack deployment after activation
    system.activationScripts.postActivation.text = lib.mkIf (cfg.packs != { }) ''
      _packs_changed=0
      # Ensure dataDir exists so we can deploy packs to it
      mkdir -p "${cfg.dataDir}"
      /usr/sbin/chown "${cfg.serviceUser}:${cfg.serviceGroup}" "${cfg.dataDir}"
      
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: src: ''
          _result=$(${deployPackScript}/bin/cribl-deploy-pack \
            "${name}" "${src}" "${cfg.dataDir}" \
            "${cfg.serviceUser}" "${cfg.serviceGroup}")
          if [ "$_result" != "unchanged" ]; then
            _packs_changed=1
            echo "${ts} [INFO] Cribl Edge pack ${name}: $_result"
          fi
        '') cfg.packs
      )}
      if [ "$_packs_changed" -eq 1 ]; then
        echo "${ts} [INFO] Packs updated"
      fi
    '';

    launchd.daemons.cribl-edge = {
      serviceConfig = {
        Label = "com.nix-darwin.cribl-edge";
        ProgramArguments = [ "${startScript}/bin/cribl-edge-start" ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        UserName = cfg.serviceUser;
        GroupName = cfg.serviceGroup;
        WorkingDirectory = cfg.dataDir;
        StandardOutPath = "/var/log/cribl-stdout.log";
        StandardErrorPath = "/var/log/cribl-stderr.log";
      };
    };
  };
}
