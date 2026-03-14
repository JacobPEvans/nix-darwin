# AI Model Volumes Configuration Module (Darwin)
#
# Manages dedicated APFS volumes for AI model storage:
# - OllamaModels: dedicated volume for Ollama model files
# - HuggingFaceModels: dedicated volume for HuggingFace model files
#
# Usage:
#   programs.ai-volumes = {
#     enable = true;
#     apfsContainer = "disk3";  # Find with: diskutil apfs list
#     ollamaVolume = {
#       enable = true;          # default: true
#       name = "OllamaModels";  # default
#       quota = "500g";         # default
#     };
#     huggingfaceVolume = {
#       enable = true;              # default: true
#       name = "HuggingFaceModels"; # default
#       quota = "400g";             # default
#     };
#   };
#
# Why separate volumes?
# - AI models can be very large (tens to hundreds of GB)
# - Dedicated APFS volumes provide clear disk space visibility
# - APFS quotas prevent runaway disk usage
# - Volumes share container space dynamically (no wasted pre-allocation)

{
  lib,
  config,
  ...
}:

let
  cfg = config.programs.ai-volumes;
  volumeScript = ./scripts/ensure-apfs-volume.sh;

  # Quota format type: must match <number><unit> (e.g., 500g, 400m, 1t)
  quotaType = lib.types.nullOr (lib.types.strMatching "^[0-9]+[gGtTmM]$");

  # Helper to generate volume option sets, reducing duplication
  mkVolumeOpts =
    {
      displayName,
      defaultName,
      defaultQuota,
    }:
    {
      enable = lib.mkEnableOption "${displayName} models volume" // {
        default = true;
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = defaultName;
        description = "Name of the APFS volume for ${displayName} model storage.";
      };

      quota = lib.mkOption {
        type = quotaType;
        default = defaultQuota;
        description = "Optional APFS quota for the ${displayName} models volume (e.g., \"500g\").";
        example = defaultQuota;
      };
    };

  # Helper to generate a launchd daemon config for a volume
  mkVolumeDaemon = daemonName: volumeCfg: {
    ${daemonName} = {
      serviceConfig = {
        Label = "com.nix-darwin.${daemonName}";
        ProgramArguments = [
          "/bin/bash"
          "${volumeScript}"
          volumeCfg.name
          cfg.apfsContainer
        ]
        ++ lib.optional (volumeCfg.quota != null) volumeCfg.quota;
        RunAtLoad = true;
        LaunchOnlyOnce = true;
        UserName = "root";
        GroupName = "wheel";
      };
    };
  };

  anyVolumeEnabled = cfg.ollamaVolume.enable || cfg.huggingfaceVolume.enable;
in
{
  options.programs.ai-volumes = {
    enable = lib.mkEnableOption "dedicated APFS volumes for AI models";

    apfsContainer = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        APFS container identifier where the volumes will be created.
        Find yours with: diskutil apfs list
        Usually "disk3" on Apple Silicon Macs with single internal storage.
      '';
      example = "disk3";
    };

    ollamaVolume = mkVolumeOpts {
      displayName = "Ollama";
      defaultName = "OllamaModels";
      defaultQuota = "500g";
    };

    huggingfaceVolume = mkVolumeOpts {
      displayName = "HuggingFace";
      defaultName = "HuggingFaceModels";
      defaultQuota = "400g";
    };
  };

  config = lib.mkIf cfg.enable {
    # Validate apfsContainer is set when at least one volume is enabled
    assertions = [
      {
        assertion = !anyVolumeEnabled || cfg.apfsContainer != "";
        message = "programs.ai-volumes.apfsContainer must be set. Find yours with: diskutil apfs list";
      }
    ];

    launchd.daemons = lib.mkMerge [
      (lib.mkIf cfg.ollamaVolume.enable (mkVolumeDaemon "ai-volumes-ollama" cfg.ollamaVolume))
      (lib.mkIf cfg.huggingfaceVolume.enable (
        mkVolumeDaemon "ai-volumes-huggingface" cfg.huggingfaceVolume
      ))
    ];
  };
}
