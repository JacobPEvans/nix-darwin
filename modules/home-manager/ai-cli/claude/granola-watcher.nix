# Granola Watcher: watchexec-driven automatic meeting migration
#
# Watches granola/ for new .md files, triggers granola-migrate.sh which
# invokes Claude headless to run the granola-merger skill.
#
# We generate the plist directly (bypassing home-manager's launchd.agents)
# because HM wraps ProgramArguments with /bin/sh, causing macOS to show
# "sh" in Login Items instead of the service name.
#
# Options: ./granola-watcher/options.nix
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

  # Named script so macOS shows "granola-watcher" in Login Items.
  # We handle /nix/store readiness ourselves since we bypass HM's wait4path wrapper.
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
    }:/opt/homebrew/bin:/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/usr/bin:/bin";
  }
  // lib.optionalAttrs cfg.apiKeyHelper.enable {
    API_KEY_HELPER = "${homeDir}/${cfg.apiKeyHelper.scriptPath}";
  };

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
    (lib.mkIf (cfg.enable && wCfg.enable) {
      home.file.".claude/scripts/granola-migrate.sh" = {
        source = ./granola-migrate.sh;
        executable = true;
      };
    })

    # Always registered so disabling cleans up the LaunchAgent
    (lib.mkIf cfg.enable {
      home.activation.manageGranolaWatcher = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        PLIST_DST="${plistDst}"
        LABEL="${label}"

        ${
          if wCfg.enable then
            ''
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
