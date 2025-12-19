# Auto-Claude: Scheduled Autonomous Maintenance
#
# Configures launchd agents to run Claude autonomously on git repositories
# at scheduled times. Uses the apiKeyHelper for headless authentication.
# Sends rich Slack notifications via Python notifier.
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

  # Python with slack-sdk for notifications
  # Override slack-sdk to disable tests that fail in CI
  pythonWithSlack = pkgs.python3.withPackages (ps: [
    (ps.slack-sdk.overridePythonAttrs (_: {
      doCheck = false; # Disable tests - they fail in CI with connection/signal errors
    }))
    ps.pyyaml
  ]);

  # Convert time spec to launchd calendar interval
  # Supports both simple hour (int) and {hour, minute} attrset
  mkCalendarInterval =
    time:
    if builtins.isInt time then
      {
        Hour = time;
        Minute = 0;
      }
    else
      {
        Hour = time.hour;
        Minute = time.minute or 0;
      };

  # Normalize schedule settings (supports single hour, list of hours, or list of times)
  getScheduleTimes =
    schedule:
    let
      timesList = schedule.times;
      hoursList = schedule.hours;
      hourOpt = schedule.hour;
    in
    if timesList != [ ] then
      timesList
    else if hoursList != [ ] then
      hoursList
    else if hourOpt != null then
      [ hourOpt ]
    else
      [ ];

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
                    type = lib.types.nullOr (lib.types.ints.between 0 23);
                    default = null;
                    description = "Hour of day to run (0-23). Deprecated in favor of hours/times.";
                  };

                  hours = lib.mkOption {
                    type = lib.types.listOf (lib.types.ints.between 0 23);
                    default = [ ];
                    description = ''
                      List of hours (0-23) to run each day at minute 0.
                      Deprecated in favor of times for hour+minute control.
                    '';
                  };

                  times = lib.mkOption {
                    type = lib.types.listOf (
                      lib.types.submodule {
                        options = {
                          hour = lib.mkOption {
                            type = lib.types.ints.between 0 23;
                            description = "Hour of day (0-23)";
                          };
                          minute = lib.mkOption {
                            type = lib.types.ints.between 0 59;
                            default = 0;
                            description = "Minute of hour (0-59)";
                          };
                        };
                      }
                    );
                    default = [
                      {
                        hour = 14;
                        minute = 0;
                      }
                    ];
                    description = ''
                      List of times to run each day. Each time has hour (0-23) and minute (0-59).

                      Default runs once daily at 2:00 PM to minimize unexpected costs.
                      Add more times for more frequent maintenance runs.

                      Example:
                        times = [
                          { hour = 9; minute = 30; }   # 9:30 AM
                          { hour = 14; minute = 0; }   # 2:00 PM
                          { hour = 18; minute = 30; }  # 6:30 PM
                        ];
                    '';
                  };
                };
              };
              description = "When to run the maintenance task";
            };

            maxBudget = lib.mkOption {
              type = lib.types.float;
              default = 20.0;
              description = ''
                Maximum cost per run in USD.

                NOTE: This default was increased from $2.0 to $20.0 to allow more
                substantial maintenance work per run. Adjust based on your usage
                and cost tolerance. With the default once-daily schedule, this
                means up to $20/day per repository.
              '';
            };

            slackChannel = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Slack channel ID for notifications (e.g., C0123456789)";
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
    # Ensure each enabled repository has at least one scheduled time
    assertions = lib.mapAttrsToList (
      name: repoCfg:
      let
        timesList = getScheduleTimes repoCfg.schedule;
      in
      {
        assertion = (!repoCfg.enabled) || (timesList != [ ]);
        message = "programs.claude.autoClaude.repositories.${name} must set schedule.times, schedule.hours, or schedule.hour when enabled";
      }
    ) enabledRepos;

    # Warn if apiKeyHelper is not enabled (required for headless auth)
    warnings = lib.optional (!cfg.apiKeyHelper.enable) ''
      programs.claude.autoClaude is enabled but programs.claude.apiKeyHelper is not.
      Auto-Claude requires apiKeyHelper for headless authentication.
      Enable it with: programs.claude.apiKeyHelper.enable = true;
    '';

    # Add Python with slack-sdk to path and deploy scripts
    home = {
      packages = [ pythonWithSlack ];

      file = {
        # Deploy shell script
        ".claude/scripts/auto-claude.sh" = {
          source = ./auto-claude.sh;
          executable = true;
        };

        # Deploy control script for runtime pause/resume/status
        ".claude/scripts/auto-claude-ctl.sh" = {
          source = ./auto-claude-ctl.sh;
          executable = true;
        };

        # Deploy orchestrator prompt
        ".claude/scripts/orchestrator-prompt.txt" = {
          source = ./orchestrator-prompt.txt;
        };

        # Deploy Python notifier
        ".claude/scripts/auto-claude-notify.py" = {
          source = ./auto-claude-notify.py;
          executable = true;
        };
      };

      # Shell alias for convenient access to control script
      shellAliases = {
        auto-claude-ctl = "${homeDir}/.claude/scripts/auto-claude-ctl.sh";
      };
    };

    # Add shell alias for convenience
    programs.zsh.shellAliases = {
      auto-claude-ctl = "${homeDir}/.claude/scripts/auto-claude-ctl.sh";
    };

    # Create launchd agents for each repository (Darwin only)
    # Each agent calls the same script with repository-specific arguments
    launchd.agents = lib.mapAttrs' (
      name: repoCfg:
      let
        timesList = getScheduleTimes repoCfg.schedule;
        slackArg = if repoCfg.slackChannel != null then repoCfg.slackChannel else "";
      in
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
            slackArg
          ];
          StartCalendarInterval = map mkCalendarInterval timesList;
          StandardOutPath = "${logDir}/launchd-${name}.log";
          StandardErrorPath = "${logDir}/launchd-${name}.err";
          EnvironmentVariables = {
            HOME = homeDir;
            PATH = "${pythonWithSlack}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
        };
      }
    ) enabledRepos;
  };
}
