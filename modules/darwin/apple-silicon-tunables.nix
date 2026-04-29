# Apple Silicon System Tunables
#
# Boot-time and runtime knobs for Apple Silicon (M-series) hosts that run
# heavy local AI inference workloads (vllm-mlx, screenpipe, etc.).
# All knobs target native macOS surfaces (sysctl, pmset, mdutil, tmutil,
# user defaults) — there is no first-class nix-darwin option for any of them.

{ lib, config, pkgs, ... }:

let
  cfg = config.system.appleSiliconTunables;
  userConfig = import ../../lib/user-config.nix;

  applyScript = pkgs.writeShellApplication {
    name = "apple-silicon-tunables-apply";
    runtimeInputs = [ ];
    text = builtins.readFile ./scripts/apple-silicon-tunables.sh;
  };
in
{
  options.system.appleSiliconTunables = {
    enable = lib.mkEnableOption "Apple Silicon system tunables for AI workloads";

    wiredLimitMb = lib.mkOption {
      type = lib.types.ints.positive;
      default = 118000;
      description = ''
        iogpu.wired_limit_mb — wired-memory ceiling for the IOGPU subsystem.
        Default 118000 = ~92% of a 128 GB host. Re-applied at every boot via
        a one-shot launchd daemon.
      '';
    };

    huggingfaceVolume = lib.mkOption {
      type = lib.types.str;
      default = "/Volumes/HuggingFace";
      description = "Path to the HuggingFace cache volume; Spotlight indexing is disabled here.";
    };

    timeMachineExcludes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "${userConfig.user.homeDir}/.cache/uv"
        "${userConfig.user.homeDir}/.cache/nix-screenpipe"
        "${userConfig.user.homeDir}/.screenpipe/data"
        "/Volumes/HuggingFace"
      ];
      description = "Absolute paths to add to the Time Machine exclusion list.";
    };

    appNapDisabledFor = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "dev.vllm-mlx.server" ];
      description = ''
        User-defaults bundle IDs to mark NSAppSleepDisabled=YES for, so macOS
        does not throttle long-lived inference daemons via App Nap.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Boot-time: re-apply the wired-memory ceiling on every restart. The
    # sysctl is volatile, so we rely on launchd RunAtLoad rather than
    # baking it into a /etc/sysctl.conf-style mechanism.
    launchd.daemons.set-iogpu-wired-limit = {
      serviceConfig = {
        Label = "dev.local.set-iogpu-wired-limit";
        ProgramArguments = [
          "/usr/sbin/sysctl"
          "-w"
          "iogpu.wired_limit_mb=${toString cfg.wiredLimitMb}"
        ];
        RunAtLoad = true;
        KeepAlive = false;
        StandardOutPath = "/var/log/set-iogpu-wired-limit.log";
        StandardErrorPath = "/var/log/set-iogpu-wired-limit.log";
      };
    };

    # darwin-rebuild switch: invoke the apply script with the configured knobs.
    system.activationScripts.appleSiliconTunables.text = ''
      WIRED_LIMIT_MB="${toString cfg.wiredLimitMb}" \
      HF_VOLUME="${cfg.huggingfaceVolume}" \
      TM_EXCLUDES="${lib.concatStringsSep ":" cfg.timeMachineExcludes}" \
      APPNAP_BUNDLES="${lib.concatStringsSep ":" cfg.appNapDisabledFor}" \
      USER_NAME="${userConfig.user.name}" \
        ${lib.getExe applyScript} || true
    '';
  };
}
