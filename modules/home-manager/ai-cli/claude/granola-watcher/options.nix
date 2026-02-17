# Granola Watcher Options
#
# Options for file-watcher-driven automatic Granola meeting migration.
# watchexec watches granola/ for new .md files and triggers Claude headless
# to run the granola-merger skill.
#
# Implementation in: ../granola-watcher.nix
{ lib, ... }:

{
  options.programs.claude.granolaWatcher = {
    enable = lib.mkEnableOption "Granola file watcher for automatic meeting migration";

    vaultPath = lib.mkOption {
      type = lib.types.str;
      description = "Absolute path to the Obsidian vault containing granola/ folder";
      example = "/Users/jevans/obsidian/obsidian-visicore";
    };

    maxBudgetPerRun = lib.mkOption {
      type = lib.types.float;
      default = 3.0;
      description = ''
        Maximum cost per Claude invocation in USD.
        Each watchexec trigger runs one Claude headless session capped at this amount.
      '';
    };

    dailyBudgetCap = lib.mkOption {
      type = lib.types.float;
      default = 10.0;
      description = ''
        Maximum cumulative USD per 24-hour period.
        Once reached, the migration script exits without invoking Claude
        until the next calendar day.
      '';
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "sonnet";
      description = ''
        Claude model to use for headless migration runs.
        Recommended: "sonnet" - good balance of cost and capability for migration tasks.
        Alternatives: "haiku" (cheaper), "opus" (higher quality, higher cost).
      '';
    };

    maxTurns = lib.mkOption {
      type = lib.types.int;
      default = 80;
      description = "Maximum conversation turns per Claude invocation";
    };

    debounce = lib.mkOption {
      type = lib.types.str;
      default = "30s";
      description = ''
        watchexec debounce period. Waits this long after the last file change
        before triggering the migration script. Set high enough for Granola Sync
        to finish writing all files (syncs every 5 minutes).
      '';
    };
  };
}
