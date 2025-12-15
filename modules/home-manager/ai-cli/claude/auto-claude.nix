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
  pythonWithSlack = pkgs.python3.withPackages (ps: [
    ps.slack-sdk
    ps.pyyaml
  ]);

  # Convert hour to launchd calendar interval
  mkCalendarInterval = hour: {
    Hour = hour;
    Minute = 0;
  };

  # Normalize schedule settings (supports single hour or list of hours)
  getScheduleHours =
    schedule:
    let
      hoursList = schedule.hours;
      hourOpt = schedule.hour;
    in
    if hoursList != [ ] then
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
                    description = "Hour of day to run (0-23). Deprecated in favor of hours.";
                  };

                  hours = lib.mkOption {
                    type = lib.types.listOf (lib.types.ints.between 0 23);
                    default = [
                      2
                      7
                      12
                      17
                      22
                    ];
                    description = "List of hours (0-23) to run each day";
                  };
                };
              };
              description = "When to run the maintenance task";
            };

            maxBudget = lib.mkOption {
              type = lib.types.float;
              default = 20.0;
              description = "Maximum cost per run in USD";
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
    # Ensure each repository has at least one scheduled hour
    assertions = lib.mapAttrsToList (
      name: repoCfg:
      let
        hoursList = getScheduleHours repoCfg.schedule;
      in
      {
        assertion = hoursList != [ ];
        message =
          "programs.claude.autoClaude.repositories." + name + " must set schedule.hours or schedule.hour";
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
    };

    # Create launchd agents for each repository (Darwin only)
    # Each agent calls the same script with repository-specific arguments
    launchd.agents = lib.mapAttrs' (
      name: repoCfg:
      let
        hoursList = getScheduleHours repoCfg.schedule;
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
          StartCalendarInterval = map mkCalendarInterval hoursList;
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
