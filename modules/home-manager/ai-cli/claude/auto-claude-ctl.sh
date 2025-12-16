#!/usr/bin/env zsh

# =============================================================================
# auto-claude-ctl: Runtime Control for Auto-Claude Scheduler
# =============================================================================
# Provides runtime control over auto-claude scheduling without modifying Nix.
# Uses a control file that auto-claude.sh checks before each run.
#
# Usage: auto-claude-ctl <command> [args...]
#
# Commands:
#   now                   Trigger immediate run (sets flag for next launchd trigger)
#   run                   Actually run auto-claude immediately (bypasses scheduler)
#   pause <hours>         Pause all runs for specified hours
#   skip <count>          Skip the next N scheduled runs
#   resume                Clear pause/skip, resume normal schedule
#   status                Show current control state and schedule
#   schedule [h:m ...]    Show or set override schedule (e.g., "9:30 14:00 18:30")
#   clear-schedule        Clear override schedule, use Nix-defined times
#
# Control file: ~/.claude/auto-claude-control.json
# =============================================================================

set -euo pipefail

CONTROL_FILE="${HOME}/.claude/auto-claude-control.json"
SCRIPT_DIR="${HOME}/.claude/scripts"
AUTO_CLAUDE_SCRIPT="${SCRIPT_DIR}/auto-claude.sh"

# Ensure control directory exists
mkdir -p "$(dirname "$CONTROL_FILE")"

# Initialize control file if missing
init_control_file() {
  if [[ ! -f "$CONTROL_FILE" ]]; then
    cat > "$CONTROL_FILE" << 'EOF'
{
  "pause_until": null,
  "skip_count": 0,
  "run_now": false,
  "override_schedule": null,
  "last_run": null,
  "last_run_repo": null,
  "notes": "Control file for auto-claude scheduling. Edit with auto-claude-ctl."
}
EOF
  fi
}

# Read JSON field (requires jq)
read_field() {
  local field="$1"
  jq -r ".$field // empty" "$CONTROL_FILE" 2>/dev/null || echo ""
}

# Update JSON field
update_field() {
  local field="$1"
  local value="$2"
  local tmp=$(mktemp)
  jq ".$field = $value" "$CONTROL_FILE" > "$tmp" && mv "$tmp" "$CONTROL_FILE"
}

# Format timestamp for display
format_time() {
  local ts="$1"
  if [[ -z "$ts" || "$ts" == "null" ]]; then
    echo "never"
  else
    # Convert ISO to readable format
    date -j -f "%Y-%m-%dT%H:%M:%S" "${ts%%.*}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$ts"
  fi
}

# Command: now - set flag for next run
cmd_now() {
  init_control_file
  update_field "run_now" "true"
  echo "Run-now flag set. Auto-claude will run on next launchd trigger."
  echo ""
  echo "To run immediately without waiting for scheduler:"
  echo "  auto-claude-ctl run"
}

# Command: run - actually run auto-claude now
cmd_run() {
  init_control_file

  # Find configured repository paths from launchd plists
  local plist_dir="${HOME}/Library/LaunchAgents"
  local repo_path=""
  local max_budget=""
  local log_dir="${HOME}/.claude/logs"
  local slack_channel=""

  # Try to find auto-claude plist
  for plist in "$plist_dir"/com.claude.auto-claude-*.plist; do
    if [[ -f "$plist" ]]; then
      # Extract arguments from plist (ProgramArguments array)
      repo_path=$(/usr/libexec/PlistBuddy -c "Print :ProgramArguments:1" "$plist" 2>/dev/null || true)
      max_budget=$(/usr/libexec/PlistBuddy -c "Print :ProgramArguments:2" "$plist" 2>/dev/null || true)
      log_dir=$(/usr/libexec/PlistBuddy -c "Print :ProgramArguments:3" "$plist" 2>/dev/null || true)
      slack_channel=$(/usr/libexec/PlistBuddy -c "Print :ProgramArguments:4" "$plist" 2>/dev/null || true)
      break
    fi
  done

  if [[ -z "$repo_path" || -z "$max_budget" ]]; then
    echo "Error: Could not find auto-claude configuration in LaunchAgents" >&2
    echo "Looking for: $plist_dir/com.claude.auto-claude-*.plist" >&2
    exit 1
  fi

  echo "Running auto-claude immediately..."
  echo "  Repository: $repo_path"
  echo "  Budget: \$${max_budget}"
  echo ""

  # Clear run_now flag since we're running
  update_field "run_now" "false"

  # Run with --force to bypass pause/skip checks
  FORCE_RUN=1 "$AUTO_CLAUDE_SCRIPT" "$repo_path" "$max_budget" "$log_dir" "$slack_channel"
}

# Command: pause - pause for N hours
cmd_pause() {
  local hours="${1:-}"
  if [[ -z "$hours" || ! "$hours" =~ ^[0-9]+$ ]]; then
    echo "Usage: auto-claude-ctl pause <hours>" >&2
    exit 1
  fi

  init_control_file
  local pause_until=$(date -v "+${hours}H" "+%Y-%m-%dT%H:%M:%S")
  update_field "pause_until" "\"$pause_until\""

  echo "Auto-claude paused until $(format_time "$pause_until")"
  echo "Run 'auto-claude-ctl resume' to resume earlier."
}

# Command: skip - skip next N runs
cmd_skip() {
  local count="${1:-}"
  if [[ -z "$count" || ! "$count" =~ ^[0-9]+$ ]]; then
    echo "Usage: auto-claude-ctl skip <count>" >&2
    exit 1
  fi

  init_control_file
  update_field "skip_count" "$count"

  echo "Will skip the next $count scheduled run(s)."
  echo "Run 'auto-claude-ctl resume' to clear."
}

# Command: resume - clear pause/skip
cmd_resume() {
  init_control_file
  update_field "pause_until" "null"
  update_field "skip_count" "0"

  echo "Resumed normal scheduling. Pause and skip cleared."
}

# Command: status - show current state
cmd_status() {
  init_control_file

  echo "Auto-Claude Control Status"
  echo "=========================="
  echo ""

  local pause_until=$(read_field "pause_until")
  local skip_count=$(read_field "skip_count")
  local run_now=$(read_field "run_now")
  local override=$(jq -c '.override_schedule // empty' "$CONTROL_FILE" 2>/dev/null)
  local last_run=$(read_field "last_run")
  local last_repo=$(read_field "last_run_repo")

  # Check pause status
  if [[ -n "$pause_until" && "$pause_until" != "null" ]]; then
    local now=$(date "+%Y-%m-%dT%H:%M:%S")
    if [[ "$now" < "$pause_until" ]]; then
      echo "Status: PAUSED until $(format_time "$pause_until")"
    else
      echo "Status: Active (pause expired)"
    fi
  elif [[ "$skip_count" -gt 0 ]] 2>/dev/null; then
    echo "Status: SKIPPING next $skip_count run(s)"
  else
    echo "Status: Active"
  fi

  echo ""
  echo "Run-now flag: $run_now"
  echo "Skip count: ${skip_count:-0}"
  echo ""

  if [[ -n "$override" && "$override" != "null" ]]; then
    echo "Override schedule: $override"
  else
    echo "Schedule: Using Nix-defined times"
  fi

  echo ""
  echo "Last run: $(format_time "$last_run") (${last_repo:-unknown repo})"
  echo ""
  echo "Control file: $CONTROL_FILE"
}

# Command: schedule - show or set override schedule
cmd_schedule() {
  init_control_file

  if [[ $# -eq 0 ]]; then
    # Show current schedule
    local override=$(jq -c '.override_schedule // empty' "$CONTROL_FILE" 2>/dev/null)
    if [[ -n "$override" && "$override" != "null" ]]; then
      echo "Override schedule active:"
      echo "$override" | jq -r '.[] | "  \(.hour):\(if .minute < 10 then "0" else "" end)\(.minute)"'
    else
      echo "No override schedule. Using Nix-defined times."
      echo ""
      echo "To set override: auto-claude-ctl schedule 9:00 14:30 18:00"
    fi
  else
    # Parse and set schedule
    local schedule="["
    local first=true
    for time in "$@"; do
      if [[ ! "$time" =~ ^([0-9]+):([0-9]+)$ ]]; then
        echo "Error: Invalid time format '$time'. Use H:MM or HH:MM (e.g., 9:30 or 14:00)" >&2
        exit 1
      fi
      local hour="${BASH_REMATCH[1]}"
      local minute="${BASH_REMATCH[2]}"

      if [[ "$hour" -lt 0 || "$hour" -gt 23 ]]; then
        echo "Error: Hour must be 0-23, got $hour" >&2
        exit 1
      fi
      if [[ "$minute" -lt 0 || "$minute" -gt 59 ]]; then
        echo "Error: Minute must be 0-59, got $minute" >&2
        exit 1
      fi

      if [[ "$first" == "true" ]]; then
        first=false
      else
        schedule+=","
      fi
      schedule+="{\"hour\":$hour,\"minute\":$minute}"
    done
    schedule+="]"

    update_field "override_schedule" "$schedule"
    echo "Override schedule set:"
    echo "$schedule" | jq -r '.[] | "  \(.hour):\(if .minute < 10 then "0" else "" end)\(.minute)"'
    echo ""
    echo "Note: This overrides Nix-defined schedule until cleared."
    echo "Run 'auto-claude-ctl clear-schedule' to restore Nix schedule."
  fi
}

# Command: clear-schedule - clear override schedule
cmd_clear_schedule() {
  init_control_file
  update_field "override_schedule" "null"
  echo "Override schedule cleared. Using Nix-defined times."
}

# Main dispatch
case "${1:-}" in
  now)
    cmd_now
    ;;
  run)
    cmd_run
    ;;
  pause)
    shift
    cmd_pause "$@"
    ;;
  skip)
    shift
    cmd_skip "$@"
    ;;
  resume)
    cmd_resume
    ;;
  status)
    cmd_status
    ;;
  schedule)
    shift
    cmd_schedule "$@"
    ;;
  clear-schedule)
    cmd_clear_schedule
    ;;
  -h|--help|help|"")
    cat << 'EOF'
auto-claude-ctl: Runtime control for auto-claude scheduler

Usage: auto-claude-ctl <command> [args...]

Commands:
  now                   Set flag for next scheduled trigger to run
  run                   Run auto-claude immediately (bypass scheduler)
  pause <hours>         Pause all runs for specified hours
  skip <count>          Skip the next N scheduled runs
  resume                Clear pause/skip, resume normal schedule
  status                Show current control state
  schedule [h:m ...]    Show or set override schedule times
  clear-schedule        Clear override, use Nix-defined times
  help                  Show this help

Examples:
  auto-claude-ctl pause 4          # Pause for 4 hours
  auto-claude-ctl skip 2           # Skip next 2 runs
  auto-claude-ctl schedule 9:00 14:30 18:00  # Run at these times
  auto-claude-ctl run              # Run right now

Control file: ~/.claude/auto-claude-control.json
EOF
    ;;
  *)
    echo "Unknown command: $1" >&2
    echo "Run 'auto-claude-ctl help' for usage." >&2
    exit 1
    ;;
esac
