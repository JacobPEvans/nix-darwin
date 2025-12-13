# Auto-Claude: Scheduled Autonomous Maintenance
#
# Configures launchd agents to run Claude autonomously on git repositories
# at scheduled times. Uses the apiKeyHelper for headless authentication.
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.claude;
  homeDir = config.home.homeDirectory;

  # Build a script for each repository
  mkAutoClaudeScript = name: repoCfg:
    pkgs.substituteAll {
      src = ./auto-claude.sh;
      targetDir = repoCfg.path;
      maxBudget = toString repoCfg.maxBudget;
      logDir = "${homeDir}/.claude/logs";
    };

  # Convert hour to launchd calendar interval
  mkCalendarInterval = hour: {
    Hour = hour;
    Minute = 0;
  };

in {
  options.programs.claude.autoClaude = {
    enable = lib.mkEnableOption "Auto-Claude scheduled maintenance";

    repositories = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          path = lib.mkOption {
            type = lib.types.str;
            description = "Absolute path to the git repository";
          };

          schedule = lib.mkOption {
            type = lib.types.submodule {
              options = {
                hour = lib.mkOption {
                  type = lib.types.int;
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
      });
      default = { };
      description = "Repositories to run auto-claude on";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.autoClaude.enable) {
    # Deploy scripts for each repository
    home.file = lib.mapAttrs' (name: repoCfg:
      lib.nameValuePair ".claude/scripts/auto-claude-${name}.sh" {
        source = mkAutoClaudeScript name repoCfg;
        executable = true;
      }) (lib.filterAttrs (_: r: r.enabled) cfg.autoClaude.repositories);

    # Create launchd agents for each repository (Darwin only)
    launchd.agents = lib.mapAttrs' (name: repoCfg:
      lib.nameValuePair "com.claude.auto-claude-${name}" {
        enable = repoCfg.enabled;
        config = {
          Label = "com.claude.auto-claude-${name}";
          ProgramArguments =
            [ "${homeDir}/.claude/scripts/auto-claude-${name}.sh" ];
          StartCalendarInterval =
            [ (mkCalendarInterval repoCfg.schedule.hour) ];
          StandardOutPath = "${homeDir}/.claude/logs/launchd-${name}.log";
          StandardErrorPath = "${homeDir}/.claude/logs/launchd-${name}.err";
          EnvironmentVariables = {
            HOME = homeDir;
            PATH =
              "/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          # Don't run if missed (e.g., laptop was asleep)
          # Set to true if you want catch-up runs
          StartCalendarInterval =
            [ (mkCalendarInterval repoCfg.schedule.hour) ];
        };
      }) (lib.filterAttrs (_: r: r.enabled) cfg.autoClaude.repositories);
  };
}
