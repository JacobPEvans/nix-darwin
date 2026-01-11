# Powerline Theme - Claude Code Statusline
#
# Multi-line statusline powered by @owloops/claude-powerline.
# Uses bunx at runtime for simplicity - no build-time hashes to maintain.
#
# Repository: https://github.com/Owloops/claude-powerline
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.claudeStatusline;

  # Configuration for claude-powerline
  powerlineConfig = {
    theme = "rose-pine";
    style = "capsule";
    charset = "unicode";
    autoWrap = false;

    display = {
      lines = [
        # Line 1: Model, Context
        {
          segments = {
            model = {
              enabled = true;
            };
            context = {
              enabled = true;
              showPercentageOnly = false;
            };
          };
        }
        # Line 2: Git info (repo, branch, behind, clean, changes - NO sha, directory, upstream)
        {
          segments = {
            git = {
              enabled = true;
              showRepoName = true;
              showBranch = true;
              showBehind = true;
              showClean = true;
              showChanges = true;
              # Disabled
              showSha = false;
              showUpstream = false;
              showWorktree = false;
              showStash = false;
            };
            directory = {
              enabled = false;
            };
          };
        }
        # Line 3: Session (tokens), Today (breakdown)
        {
          segments = {
            session = {
              enabled = true;
              type = "tokens";
            };
            today = {
              enabled = true;
              type = "breakdown";
            };
            # Disabled
            block = {
              enabled = false;
            };
            metrics = {
              enabled = false;
            };
            version = {
              enabled = false;
            };
          };
        }
      ];
    };

    # Budget warnings at 80%
    budget = {
      session = {
        amount = 10.0;
        type = "tokens";
        warningThreshold = 80;
      };
      today = {
        amount = 25.0;
        type = "tokens";
        warningThreshold = 80;
      };
    };
  };

  # Write config to JSON file
  configFile = pkgs.writeText "claude-powerline.json" (builtins.toJSON powerlineConfig);

in
{
  config = lib.mkIf cfg.enable {
    programs.claude.statusLine = {
      enable = true;
      script = ''
        #!/usr/bin/env bash
        # Claude Powerline statusline
        # Uses bunx for runtime execution (no build-time hash maintenance)
        exec ${pkgs.bun}/bin/bunx @owloops/claude-powerline --config=${configFile} "$@"
      '';
    };
  };
}
