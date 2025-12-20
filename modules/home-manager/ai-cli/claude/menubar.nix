# Auto-Claude Menu Bar Status
#
# SwiftBar plugin for monitoring auto-claude status in real-time.
# Shows current state (active/paused/running) and provides quick actions.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.claude;

  # SwiftBar plugin script
  menubarScript = pkgs.writeShellScript "auto-claude-status.sh" ''
    #!/usr/bin/env bash
    # SwiftBar Auto-Claude Status Plugin
    # Refresh: 30s (configured via filename)

    CONTROL_FILE="$HOME/.claude/auto-claude-control.json"
    LOG_DIR="$HOME/.claude/logs"

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
      echo "⚠️"
      echo "---"
      echo "jq not found | color=red"
      exit 0
    fi

    # Initialize control file if missing
    if [[ ! -f "$CONTROL_FILE" ]]; then
      echo "🤖"
      echo "---"
      echo "No control file | color=gray"
      exit 0
    fi

    # Read status
    pause_until=$(jq -r '.pause_until // empty' "$CONTROL_FILE" 2>/dev/null)
    skip_count=$(jq -r '.skip_count // 0' "$CONTROL_FILE" 2>/dev/null)
    last_run=$(jq -r '.last_run // empty' "$CONTROL_FILE" 2>/dev/null)
    last_repo=$(jq -r '.last_run_repo // empty' "$CONTROL_FILE" 2>/dev/null)

    # Check for active Claude processes
    active_sessions=$(pgrep -f "claude.*--print" 2>/dev/null | wc -l | tr -d ' ')

    # Determine status icon
    if [[ "$active_sessions" -gt 0 ]]; then
      icon="🔄"
      status="Running ($active_sessions sessions)"
      color="blue"
    elif [[ -n "$pause_until" && "$pause_until" != "null" ]]; then
      # Check if pause is still active
      now=$(date +%s)
      if command -v gdate &>/dev/null; then
        pause_epoch=$(gdate -d "$pause_until" +%s 2>/dev/null || echo 0)
      else
        # BSD date (macOS)
        pause_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "''${pause_until%%.*}" +%s 2>/dev/null || echo 0)
      fi
      if [[ "$now" -lt "$pause_epoch" ]]; then
        icon="⏸️"
        status="Paused until $(date -j -f "%Y-%m-%dT%H:%M:%S" "''${pause_until%%.*}" "+%H:%M" 2>/dev/null || echo "$pause_until")"
        color="orange"
      else
        icon="🤖"
        status="Active (pause expired)"
        color="green"
      fi
    elif [[ "$skip_count" -gt 0 ]]; then
      icon="⏭️"
      status="Skipping $skip_count runs"
      color="yellow"
    else
      icon="🤖"
      status="Active"
      color="green"
    fi

    # Output menu bar title
    echo "$icon"
    echo "---"
    echo "Auto-Claude Status | size=14"
    echo "$status | color=$color"
    echo "---"

    # Last run info
    if [[ -n "$last_run" && "$last_run" != "null" ]]; then
      echo "Last run: $last_run"
      echo "Repo: ''${last_repo:-unknown}"
    else
      echo "Last run: never | color=gray"
    fi
    echo "---"

    # Recent logs (last 5)
    echo "Recent Logs | size=12"
    if [[ -d "$LOG_DIR" ]]; then
      ls -t "$LOG_DIR"/*.jsonl 2>/dev/null | head -5 | while read -r logfile; do
        name=$(basename "$logfile" .jsonl)
        size=$(du -h "$logfile" 2>/dev/null | cut -f1)
        echo "  $name ($size) | bash='open -R \"$logfile\"' terminal=false"
      done
    else
      echo "  No logs found | color=gray"
    fi
    echo "---"

    # Actions
    echo "Actions | size=12"
    echo "  Resume | bash='$HOME/.claude/scripts/auto-claude-ctl.sh resume' terminal=true refresh=true"
    echo "  Pause 1 hour | bash='$HOME/.claude/scripts/auto-claude-ctl.sh pause 1' terminal=true refresh=true"
    echo "  Pause 4 hours | bash='$HOME/.claude/scripts/auto-claude-ctl.sh pause 4' terminal=true refresh=true"
    echo "  Skip next run | bash='$HOME/.claude/scripts/auto-claude-ctl.sh skip 1' terminal=true refresh=true"
    echo "---"
    echo "  Run Now... | bash='$HOME/.claude/scripts/auto-claude-ctl.sh run' terminal=true"
    echo "---"
    echo "Open Logs Folder | bash='open \"$LOG_DIR\"' terminal=false"
    echo "View Status | bash='$HOME/.claude/scripts/auto-claude-ctl.sh status' terminal=true"
    echo "---"
    echo "Refresh | refresh=true"
  '';

in
{
  options.programs.claude.menubar = {
    enable = lib.mkEnableOption "Auto-Claude menu bar status via SwiftBar";

    refreshInterval = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Refresh interval in seconds for the menu bar plugin";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.menubar.enable) {
    # Deploy the SwiftBar plugin with the correct filename for refresh interval
    home.file."Library/Application Support/SwiftBar/Plugins/auto-claude.${toString cfg.menubar.refreshInterval}s.sh" =
      {
        source = menubarScript;
        executable = true;
      };

    # Add a note about SwiftBar setup
    warnings = lib.optional (!config.programs.claude.autoClaude.enable) ''
      programs.claude.menubar is enabled but programs.claude.autoClaude is not.
      The menu bar will show status but auto-claude won't be running.
    '';
  };
}
