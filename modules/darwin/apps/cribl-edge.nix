# Cribl Edge Service Management
#
# Manages Cribl Edge as a Nix-built package with a declarative launchd daemon.
# No .pkg installer, no Cribl Cloud install-edge.sh — the binary comes from
# packages/cribl-edge.nix and is immutable in the Nix store. Mutable state
# (config, queues, logs) lives under cfg.dataDir (default /opt/cribl-data).
#
# Fleet enrollment happens at first start via `cribl mode-managed-edge`:
# if instance.yml doesn't exist in dataDir, the startScript enrolls with
# Cribl Cloud using CRIBL_ORG_ID / CRIBL_WORKSPACE_ID / CRIBL_TOKEN from the
# sops-rendered secrets file. Subsequent starts skip enrollment and run
# `cribl server` directly. After enrollment Cribl Cloud manages all runtime
# configuration for the edge node.
#
# Secrets are provided via sops-nix (modules/darwin/sops.nix), which decrypts
# age-encrypted credentials to a root-only (0400) KEY=value file at activation
# time. The startScript parses this file line-by-line — no `source`, no shell
# eval — and only exports recognized CRIBL_* keys.
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

  deployPackScript = pkgs.writeShellApplication {
    name = "cribl-deploy-pack";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./scripts/cribl-edge-deploy-pack.sh;
  };

  startScript = pkgs.writeShellApplication {
    name = "cribl-edge-start";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      exec ${./scripts/cribl-edge-start.sh} \
        "${cfg.cloud.secretsFile}" \
        "${cfg.dataDir}" \
        "${cfg.package}/opt/cribl" \
        "${cfg.cloud.group}"
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
    # Always ensure dataDir + logs subdir exist with correct ownership so the
    # launchd job can write, whether or not any packs are declared.
    system.activationScripts.postActivation.text = ''
      ${./scripts/cribl-edge-activate.sh} "${cfg.dataDir}" "${cfg.serviceUser}:${cfg.serviceGroup}"
      ${lib.optionalString (cfg.packs != { }) (
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: src: ''
            ${deployPackScript}/bin/cribl-deploy-pack ${name} ${src} ${cfg.dataDir} ${cfg.serviceUser} ${cfg.serviceGroup}
          '') cfg.packs
        )
      )}
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
        StandardOutPath = "${cfg.dataDir}/logs/cribl-stdout.log";
        StandardErrorPath = "${cfg.dataDir}/logs/cribl-stderr.log";
      };
    };
  };
}
