# Maestro Auto Run Configuration Options
{
  config,
  lib,
  ...
}:

{
  options.programs.maestro = {
    enable = lib.mkEnableOption "Maestro Auto Run integration";

    issueResolver = {
      enable = lib.mkEnableOption "Issue Resolver Auto Run playbook";

      schedule = {
        hour = lib.mkOption {
          type = lib.types.int;
          default = 9;
          description = "Hour to run issue resolver (0-23)";
        };

        minute = lib.mkOption {
          type = lib.types.int;
          default = 0;
          description = "Minute to run issue resolver (0-59)";
        };
      };

      targetRepository = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/git/nix-config/main";
        description = "Target repository for issue resolution";
      };
    };
  };
}
