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

  activateScript = pkgs.writeShellApplication {
    name = "cribl-edge-activate";
    runtimeInputs = [ ];
    text = builtins.readFile ./scripts/cribl-edge-activate.sh;
  };

  deployPackScript = pkgs.writeShellApplication {
    name = "cribl-deploy-pack";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./scripts/cribl-edge-deploy-pack.sh;
  };
in
{
  options.programs.cribl-edge = {
    enable = lib.mkEnableOption "Cribl Edge service management";

    installPath = lib.mkOption {
      type = lib.types.str;
      default = "/opt/cribl";
      description = "Installation path for Cribl Edge.";
    };

    version = lib.mkOption {
      type = lib.types.str;
      description = "Cribl Edge version string (e.g., '4.17.0-7e952fa7'). Bump to upgrade.";
      example = "4.17.0-7e952fa7";
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
      orgIdCommand = lib.mkOption {
        type = lib.types.str;
        description = "Shell command that outputs the Cribl Cloud org ID.";
        example = "doppler secrets get CRIBL_ORG_ID --plain -p iac-conf-mgmt -c prd";
      };

      workspaceIdCommand = lib.mkOption {
        type = lib.types.str;
        description = "Shell command that outputs the Cribl Cloud workspace ID.";
        example = "doppler secrets get CRIBL_WORKSPACE_ID --plain -p iac-conf-mgmt -c prd";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "default_fleet";
        description = "Fleet group name.";
      };

      tokenCommand = lib.mkOption {
        type = lib.types.str;
        description = "Shell command that outputs the fleet auth token.";
        example = "doppler secrets get CRIBL_TOKEN --plain -p iac-conf-mgmt -c prd";
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
      example = lib.literalExpression ''
        {
          cc-edge-macos-power = pkgs.fetchzip {
            url = "https://github.com/JacobPEvans/cc-edge-macos-power/releases/download/v1.0.0/cc-edge-macos-power-v1.0.0.crbl";
            extension = "tar.gz";
            hash = "sha256-...";
            stripRoot = false;
          };
        }
      '';
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
      _org="$(${cfg.cloud.orgIdCommand})"
      _ws="$(${cfg.cloud.workspaceIdCommand})"
      _token="$(${cfg.cloud.tokenCommand})"
      ${activateScript}/bin/cribl-edge-activate \
        "''${_ws}-''${_org}.cribl.cloud" \
        "${cfg.cloud.group}" "$_token" \
        "${cfg.version}" "${cfg.installPath}" \
        "${cfg.serviceUser}" "${cfg.serviceGroup}"

      ${lib.optionalString (cfg.packs != { }) ''
        _packs_changed=0
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: src: ''
            _result=$(${deployPackScript}/bin/cribl-deploy-pack \
              "${name}" "${src}" "${cfg.installPath}" \
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
      ''}
    '';

    launchd.daemons.cribl-edge = {
      serviceConfig = {
        Label = "com.nix-darwin.cribl-edge";
        ProgramArguments = [
          "${cfg.installPath}/bin/cribl"
          "server"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        UserName = cfg.serviceUser;
        GroupName = cfg.serviceGroup;
        WorkingDirectory = cfg.installPath;
        StandardOutPath = "${cfg.installPath}/log/cribl-stdout.log";
        StandardErrorPath = "${cfg.installPath}/log/cribl-stderr.log";
        EnvironmentVariables = {
          CRIBL_HOME = cfg.installPath;
        };
      };
    };
  };
}
