# Granola Watcher: File-watcher-driven automatic meeting migration
#
# Uses watchexec to watch granola/ for new .md files, then triggers
# a lightweight shell script that invokes Claude headless to run
# the granola-merger skill.
#
# Architecture:
#   watchexec (long-lived, launchd KeepAlive) -> granola-migrate.sh (short-lived)
#     -> claude -p (headless, Sonnet, budget-capped)
#
# IMPORTANT: We bypass home-manager's launchd.agents because it wraps
# ProgramArguments with /bin/sh (HM PR #8609), causing macOS to display
# "sh" in Login Items and background activity notifications. Instead we
# generate the plist directly and manage lifecycle via home.activation.
# See docs/LAUNCHD-NAMING.md for the full explanation.
#
# Options defined in: ./granola-watcher/options.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.claude;
  wCfg = cfg.granolaWatcher;
  homeDir = config.home.homeDirectory;
  inherit (config.home) username;
  logDir = "${homeDir}/.claude/logs";
  migrateScript = "${homeDir}/.claude/scripts/granola-migrate.sh";
  label = "com.visicore.granola-watcher";
  plistDst = "${homeDir}/Library/LaunchAgents/${label}.plist";

  # Named launcher script so macOS shows "granola-watcher" in Login Items
  # instead of "sh". The basename of ProgramArguments[0] determines what
  # macOS displays in background activity notifications and Login Items.
  # We handle /nix/store readiness ourselves (wait4path) since we're
  # bypassing home-manager's automatic wait4path wrapper.
  launcherScript = pkgs.writeShellScript "granola-watcher" ''
    /bin/wait4path /nix/store
    exec ${pkgs.watchexec}/bin/watchexec \
      --watch "${wCfg.vaultPath}/granola" \
      --exts md \
      --postpone \
      --debounce "${wCfg.debounce}" \
      --no-vcs-ignore \
      -- "${migrateScript}"
  '';

  # Environment variables passed to watchexec via launchd
  envVars = {
    HOME = homeDir;
    VAULT_PATH = wCfg.vaultPath;
    CLAUDE_MODEL = wCfg.model;
    CLAUDE_MAX_TURNS = toString wCfg.maxTurns;
    MAX_BUDGET = toString wCfg.maxBudgetPerRun;
    DAILY_CAP = toString wCfg.dailyBudgetCap;
    LOG_DIR = logDir;
    PATH = "${
      lib.makeBinPath [
        pkgs.jq
        pkgs.bc
      ]
    }:/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/usr/bin:/bin";
  }
  // lib.optionalAttrs cfg.apiKeyHelper.enable {
    API_KEY_HELPER = "${homeDir}/${cfg.apiKeyHelper.scriptPath}";
  };

  # Generate plist directly (bypassing home-manager's mutateConfig)
  plistFile = pkgs.writeText "${label}.plist" (
    lib.generators.toPlist { escape = true; } {
      Label = label;
      AssociatedBundleIdentifiers = [ "com.mitchellh.ghostty" ];
      ProgramArguments = [ (toString launcherScript) ];
      KeepAlive = true;
      StandardOutPath = "${logDir}/granola-watcher.log";
      StandardErrorPath = "${logDir}/granola-watcher.err";
      EnvironmentVariables = envVars;
    }
  );
in
{
  imports = [ ./granola-watcher/options.nix ];

  config = lib.mkMerge [
    # When enabled: deploy migration script
    (lib.mkIf (cfg.enable && wCfg.enable) {
      home.file.".claude/scripts/granola-migrate.sh" = {
        source = ./granola-migrate.sh;
        executable = true;
      };
    })

    # LaunchAgent lifecycle: always registered so disabling cleans up properly
    (lib.mkIf cfg.enable {
      home.activation.manageGranolaWatcher = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        PLIST_DST="${plistDst}"
        LABEL="${label}"

        ${
          if wCfg.enable then
            ''
              # Granola watcher enabled: install/update LaunchAgent
              PLIST_SRC="${plistFile}"
              $DRY_RUN_CMD mkdir -p "$(dirname "$PLIST_DST")"
              $DRY_RUN_CMD mkdir -p "${logDir}"

              if ! cmp -s "$PLIST_SRC" "$PLIST_DST" 2>/dev/null; then
                $DRY_RUN_CMD launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
                $DRY_RUN_CMD install -m 444 "$PLIST_SRC" "$PLIST_DST"
                $DRY_RUN_CMD launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"
              fi
            ''
          else
            ''
              # Granola watcher disabled: remove LaunchAgent if present
              if [ -f "$PLIST_DST" ]; then
                $DRY_RUN_CMD launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
                $DRY_RUN_CMD rm -f "$PLIST_DST"
              fi
            ''
        }
      '';
    })
  ];
}
