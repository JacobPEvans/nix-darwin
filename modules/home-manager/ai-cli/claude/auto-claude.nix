# Auto-Claude: Scheduled Autonomous Maintenance
#
# Configures launchd agents to run Claude autonomously on git repositories
# at scheduled times. Uses the apiKeyHelper for headless authentication.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.claude;
  homeDir = config.home.homeDirectory;
  scriptPath = "${homeDir}/.claude/scripts/auto-claude.sh";
  logDir = "${homeDir}/.claude/logs";

  # Convert hour to launchd calendar interval
  mkCalendarInterval = hour: {
    Hour = hour;
    Minute = 0;
  };

  # Filter to only enabled repositories
  enabledRepos = lib.filterAttrs (_: r: r.enabled) cfg.autoClaude.repositories;

in
{
  options.programs.claude.autoClaude = {
    enable = lib.mkEnableOption "Auto-Claude scheduled maintenance";

    repositories = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            path = lib.mkOption {
              type = lib.types.str;
              description = "Absolute path to the git repository";
            };

            schedule = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  hour = lib.mkOption {
                    type = lib.types.ints.between 0 23;
                    description = "Hour of day to run (0-23)";
                  };
                };
              };
              description = "When to run the maintenance task";
            };

            maxBudget = lib.mkOption {
              type = lib.types.float;
              default = 2.0;
              description = "Maximum cost per run in USD";
            };

            enabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether this repository's schedule is active";
            };
          };
        }
      );
      default = { };
      description = "Repositories to run auto-claude on";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.autoClaude.enable) {
    # Warn if apiKeyHelper is not enabled (required for headless auth)
    warnings = lib.optional (!cfg.apiKeyHelper.enable) ''
      programs.claude.autoClaude is enabled but programs.claude.apiKeyHelper is not.
      Auto-Claude requires apiKeyHelper for headless authentication.
      Enable it with: programs.claude.apiKeyHelper.enable = true;
    '';

    # Deploy single parameterized script (not repo-specific)
    home.file.".claude/scripts/auto-claude.sh" = {
      source = ./auto-claude.sh;
      executable = true;
    };

    # Create launchd agents for each repository (Darwin only)
    # Each agent calls the same script with repository-specific arguments
    launchd.agents = lib.mapAttrs' (
      name: repoCfg:
      lib.nameValuePair "com.claude.auto-claude-${name}" {
        enable = repoCfg.enabled;
        config = {
          Label = "com.claude.auto-claude-${name}";
          # Pass arguments at runtime instead of baking them into the script
          ProgramArguments = [
            scriptPath
            repoCfg.path
            (toString repoCfg.maxBudget)
            logDir
          ];
          StartCalendarInterval = [ (mkCalendarInterval repoCfg.schedule.hour) ];
          StandardOutPath = "${logDir}/launchd-${name}.log";
          StandardErrorPath = "${logDir}/launchd-${name}.err";
          EnvironmentVariables = {
            HOME = homeDir;
            PATH = "/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
        };
      }
    ) enabledRepos;
  };
}
