#!/usr/bin/env zsh

# =============================================================================
# Auto-Claude: Autonomous AI Maintenance Daemon
# =============================================================================
# Runs Claude autonomously via launchd to perform maintenance tasks on git repos.
# Designed for full autonomy with safety constraints and structured logging.
#
# Usage: auto-claude.sh <target_dir> <max_budget_usd> [log_dir] [slack_channel]
#
# Arguments:
# - target_dir     : Directory to run maintenance in (required)
# - max_budget_usd : Maximum cost per run in USD (required)
# - log_dir        : Directory for log files (optional, defaults to ~/.claude/logs)
# - slack_channel  : Slack channel ID for notifications (optional)
#
# Environment:
# - FORCE_RUN=1    : Bypass pause/skip checks (used by auto-claude-ctl run)
#
# Control file: ~/.claude/auto-claude-control.json
# =============================================================================

set -euo pipefail

# --- CONTROL FILE ---
CONTROL_FILE="${HOME}/.claude/auto-claude-control.json"

# Convert ISO8601 timestamp to epoch seconds
# Supports both macOS (BSD date) and Linux (GNU date)
iso_to_epoch() {
  local iso="$1"
  if date --version >/dev/null 2>&1; then
    # GNU date (Linux)
    date -d "$iso" "+%s" 2>/dev/null
  else
    # BSD date (macOS)
    date -j -f "%Y-%m-%dT%H:%M:%S" "${iso%%.*}" "+%s" 2>/dev/null
  fi
}

# Check control file for pause/skip states
# Returns 0 if should run, exits 0 if should skip
check_control_file() {
  # Skip checks if FORCE_RUN is set (from auto-claude-ctl run)
  if [[ "${FORCE_RUN:-}" == "1" ]]; then
    return 0
  fi

  # If control file doesn't exist, proceed normally
  if [[ ! -f "$CONTROL_FILE" ]]; then
    return 0
  fi

  # Check pause_until timestamp
  local pause_until=$(jq -r '.pause_until // empty' "$CONTROL_FILE" 2>/dev/null)
  if [[ -n "$pause_until" && "$pause_until" != "null" ]]; then
    local now_epoch=$(date +%s)
    local pause_epoch=$(iso_to_epoch "$pause_until")
    if [[ -n "$pause_epoch" && "$now_epoch" -lt "$pause_epoch" ]]; then
      echo "[$(date +%Y%m%d_%H%M%S)] SKIPPED: Paused until $pause_until" >> "${HOME}/.claude/logs/summary.log"
      exit 0
    fi
  fi

  # Check skip_count
  local skip_count=$(jq -r '.skip_count // 0' "$CONTROL_FILE" 2>/dev/null)
  if [[ "$skip_count" -gt 0 ]] 2>/dev/null; then
    # Decrement skip count
    local tmp
    tmp=$(mktemp) || {
      echo "[$(date +%Y%m%d_%H%M%S)] WARNING: Could not create temp file for skip_count update" >> "${HOME}/.claude/logs/summary.log"
      exit 0
    }
    if jq ".skip_count = $((skip_count - 1))" "$CONTROL_FILE" > "$tmp"; then
      mv "$tmp" "$CONTROL_FILE"
    else
      rm -f "$tmp"
    fi
    echo "[$(date +%Y%m%d_%H%M%S)] SKIPPED: Skip count was $skip_count, now $((skip_count - 1))" >> "${HOME}/.claude/logs/summary.log"
    exit 0
  fi

  return 0
}

# Update control file with last run info
update_last_run() {
  local repo="$1"
  if [[ -f "$CONTROL_FILE" ]] && command -v jq &>/dev/null; then
    local tmp
    tmp=$(mktemp) || {
      echo "[$RUN_ID] WARNING: Could not create temp file for last_run update" >> "$SUMMARY_LOG"
      return 0
    }
    local now=$(date "+%Y-%m-%dT%H:%M:%S")
    if jq ".last_run = \"$now\" | .last_run_repo = \"$repo\"" "$CONTROL_FILE" > "$tmp"; then
      mv "$tmp" "$CONTROL_FILE"
    else
      rm -f "$tmp"
    fi
  fi
}

# Calculate total tokens used from JSONL log
calculate_token_usage() {
  local log_file="$1"

  if [[ ! -f "$log_file" ]]; then
    echo "0"
    return
  fi

  # Sum all input_tokens + output_tokens from assistant messages
  local total=$(jq -r 'select(.type == "message" and .message.role == "assistant") | .message.usage | (.input_tokens + .output_tokens)' "$log_file" 2>/dev/null | awk '{sum+=$1} END {print sum}')

  echo "${total:-0}"
}

# Check if context usage exceeded threshold
check_context_usage() {
  local total_tokens=$(calculate_token_usage "$LOG_FILE")
  local context_window=200000  # Standard tier
  local usage_pct=$((total_tokens * 100 / context_window))
  local tokens_remaining=$((context_window - total_tokens))

  echo "[$RUN_ID] Total tokens used: $total_tokens / $context_window ($usage_pct%)" >> "$SUMMARY_LOG"

  # Emit context checkpoint event for monitoring
  emit_event "context_checkpoint" \
    "tokens_used" "$total_tokens" \
    "tokens_remaining" "$tokens_remaining" \
    "usage_pct" "$usage_pct" \
    "context_window" "$context_window"

  if (( usage_pct > 90 )); then
    echo "[$RUN_ID] WARNING: Context usage exceeded 90% - orchestrator should have exited gracefully" >> "$SUMMARY_LOG"
    emit_event "context_warning" "usage_pct" "$usage_pct" "reason" "exceeded_90_percent"
  fi
}

# --- ARGUMENT PARSING ---
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <target_dir> <max_budget_usd> [log_dir] [slack_channel]" >&2
  exit 1
fi

TARGET_DIR="$1"
MAX_BUDGET_USD="$2"
LOG_DIR="${3:-$HOME/.claude/logs}"
SLACK_CHANNEL="${4:-}"

# --- DEPENDENCY CHECKS ---
if ! command -v jq &>/dev/null; then
  echo "Error: jq is not installed. Please install it to use this script." >&2
  exit 1
fi

# --- ENVIRONMENT (early, needed for bws/Slack auth) ---
# Source shell configs for full environment (API keys, PATH, git credentials)
# Required because launchd runs in a minimal shell
# Must happen BEFORE skip notifications so bws has access token
set +e
[[ -r "$HOME/.zshrc" ]] && source "$HOME/.zshrc" 2>/dev/null
[[ -r "$HOME/.profile" ]] && source "$HOME/.profile" 2>/dev/null
set -e

# --- BWS AUTHENTICATION ---
# Retrieve BWS access token from macOS Keychain for Bitwarden Secrets Manager
# This is required for Slack notifications (bot token stored in BWS)
if [[ -z "${BWS_ACCESS_TOKEN:-}" ]]; then
  BWS_TOKEN=$(security find-generic-password -s "bws-claude-automation" -w 2>/dev/null) || true
  if [[ -n "$BWS_TOKEN" ]]; then
    export BWS_ACCESS_TOKEN="$BWS_TOKEN"
  fi
fi

# --- EARLY SETUP FOR SLACK NOTIFICATIONS (needed for skip notifications) ---
SCRIPT_DIR="${HOME}/.claude/scripts"
NOTIFIER="${SCRIPT_DIR}/auto-claude-notify.py"
REPO_NAME=$(basename "${TARGET_DIR%/}")

# Check if Python notifier is available for skip notifications
SLACK_ENABLED=false
if [[ -n "$SLACK_CHANNEL" ]] && [[ -x "$NOTIFIER" ]] && command -v python3 &>/dev/null; then
  SLACK_ENABLED=true
fi

# Function to send skip notification
notify_skipped() {
  local reason="$1"
  if [[ "$SLACK_ENABLED" == "true" ]]; then
    python3 "$NOTIFIER" run_skipped \
      --repo "$REPO_NAME" \
      --reason "$reason" \
      --channel "$SLACK_CHANNEL" 2>/dev/null || true
  fi
  # Also emit structured event
  local timestamp=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
  local run_id=$(date "+%Y%m%d_%H%M%S")
  echo "{\"event\":\"run_skipped\",\"timestamp\":\"$timestamp\",\"run_id\":\"$run_id\",\"repo\":\"$REPO_NAME\",\"reason\":\"$reason\"}" >> "${HOME}/.claude/logs/events.jsonl"
}

# --- CONTROL FILE CHECK ---
CONTROL_FILE="${HOME}/.claude/auto-claude-control.json"

# Convert ISO8601 timestamp to epoch seconds for reliable comparison
# Supports both macOS (BSD date) and Linux (GNU date)
iso_to_epoch() {
  local iso="$1"
  if date --version >/dev/null 2>&1; then
    # GNU date (Linux)
    date -d "$iso" "+%s" 2>/dev/null
  else
    # BSD date (macOS)
    date -j -f "%Y-%m-%dT%H:%M:%S" "${iso%%.*}" "+%s" 2>/dev/null
  fi
}

check_control_file() {
  # Skip checks if FORCE_RUN is set
  if [[ "${FORCE_RUN:-}" == "1" ]]; then
    return 0
  fi

  # Skip if control file doesn't exist
  if [[ ! -f "$CONTROL_FILE" ]]; then
    return 0
  fi

  local now=$(date "+%Y-%m-%dT%H:%M:%S")

  # Check pause_until
  local pause_until=$(jq -r '.pause_until // empty' "$CONTROL_FILE" 2>/dev/null)
  if [[ -n "$pause_until" && "$pause_until" != "null" ]]; then
    local now_epoch=$(iso_to_epoch "$now")
    local pause_until_epoch=$(iso_to_epoch "$pause_until")
    if [[ -z "$now_epoch" || -z "$pause_until_epoch" ]]; then
      echo "Warning: Could not parse pause_until or current time. Skipping pause check." >&2
    elif [[ "$now_epoch" -lt "$pause_until_epoch" ]]; then
      echo "Auto-claude paused until $pause_until. Skipping this run." >&2
      echo "Run 'auto-claude-ctl resume' to resume earlier." >&2
      notify_skipped "Paused until $pause_until"
      exit 0
    fi
  fi

  # Check skip_count
  local skip_count=$(jq -r '.skip_count // 0' "$CONTROL_FILE" 2>/dev/null)
  if [[ "$skip_count" -gt 0 ]] 2>/dev/null; then
    local new_count=$((skip_count - 1))
    local tmp
    tmp=$(mktemp) || { echo "Error: could not create temporary file for skip_count update." >&2; exit 1; }
    jq ".skip_count = $new_count" "$CONTROL_FILE" > "$tmp" && mv "$tmp" "$CONTROL_FILE"
    echo "Skipping this run ($new_count remaining). Run 'auto-claude-ctl resume' to clear." >&2
    notify_skipped "Skip count: $new_count remaining"
    exit 0
  fi

  # Clear run_now flag if set (we're about to run)
  local run_now=$(jq -r '.run_now // false' "$CONTROL_FILE" 2>/dev/null)
  if [[ "$run_now" == "true" ]]; then
    local tmp
    tmp=$(mktemp) || { echo "Error: could not create temporary file for run_now flag clear." >&2; exit 1; }
    jq '.run_now = false' "$CONTROL_FILE" > "$tmp" && mv "$tmp" "$CONTROL_FILE"
  fi
}

# Run control file check
check_control_file

# --- INPUT VALIDATION ---
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: Directory $TARGET_DIR does not exist." >&2
  exit 1
fi

# Validate MAX_BUDGET_USD is a positive number
if ! [[ "$MAX_BUDGET_USD" =~ ^[0-9]+\.?[0-9]*$ ]] || ! awk -v val="$MAX_BUDGET_USD" 'BEGIN { exit !(val > 0) }'; then
  echo "Error: MAX_BUDGET_USD must be a positive number, got: $MAX_BUDGET_USD" >&2
  exit 1
fi

# --- LOGGING SETUP ---
if ! mkdir -p "$LOG_DIR"; then
  echo "Error: Cannot create log directory $LOG_DIR" >&2
  exit 1
fi
RUN_ID=$(date "+%Y%m%d_%H%M%S")
# Normalize path (remove trailing slashes) before extracting basename
REPO_NAME=$(basename "${TARGET_DIR%/}")
LOG_FILE="$LOG_DIR/${REPO_NAME}_${RUN_ID}.jsonl"
SUMMARY_LOG="$LOG_DIR/summary.log"
FAILURES_LOG="$LOG_DIR/failures.log"
EVENTS_LOG="$LOG_DIR/events.jsonl"

# --- STRUCTURED EVENT LOGGING ---
# Emit JSON events for monitoring systems (OTEL, Cribl, Splunk)
emit_event() {
  local event_type="$1"
  shift
  local timestamp=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
  local event_json="{\"event\":\"$event_type\",\"timestamp\":\"$timestamp\",\"run_id\":\"$RUN_ID\",\"repo\":\"$REPO_NAME\""

  # Add any additional key-value pairs
  while [[ $# -ge 2 ]]; do
    local key="$1"
    local value="$2"
    # Check if value is numeric (no quotes) or string (needs quotes)
    if [[ "$value" =~ ^[0-9]+\.?[0-9]*$ ]]; then
      event_json="$event_json,\"$key\":$value"
    else
      # Escape quotes in string values
      value="${value//\"/\\\"}"
      event_json="$event_json,\"$key\":\"$value\""
    fi
    shift 2
  done

  event_json="$event_json}"

  # Write to both events log and stdout for capture
  echo "$event_json" >> "$EVENTS_LOG"
  echo "$event_json"
}

# --- SCRIPT PATHS ---
SCRIPT_DIR="${HOME}/.claude/scripts"
NOTIFIER="${SCRIPT_DIR}/auto-claude-notify.py"
PROMPT_FILE="${SCRIPT_DIR}/orchestrator-prompt.txt"

# --- CONTROL FILE CHECK ---
# Must run early, before expensive operations
check_control_file

# --- PRE-FLIGHT CHECKS ---
cd "$TARGET_DIR" || {
  echo "[$RUN_ID] ERROR: Cannot cd to $TARGET_DIR" >> "$FAILURES_LOG"
  exit 1
}

# --- GIT PRE-FLIGHT CHECKS ---
# Ensure repository is in a clean, synced state before running
pre_flight_git_check() {
  # Get current branch
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -z "$branch" ]]; then
    echo "[$RUN_ID] WARNING: Not a git repository or git not available" >> "$SUMMARY_LOG"
    return 0  # Continue anyway - might not be a git repo
  fi

  # Must be on main or master branch
  if [[ "$branch" != "main" && "$branch" != "master" ]]; then
    echo "[$RUN_ID] ERROR: Not on main/master branch (currently on: $branch). Switch to main first." >> "$FAILURES_LOG"
    exit 1
  fi

  # CRITICAL: Check working tree is clean BEFORE any git operations
  # This prevents pull attempts on dirty trees which could cause conflicts
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    echo "[$RUN_ID] ERROR: Working tree has uncommitted changes. Commit or stash them first." >> "$FAILURES_LOG"
    git status --short >> "$FAILURES_LOG"
    exit 1
  fi

  # Fetch latest from remote (silently)
  if ! git fetch origin "$branch" --quiet 2>/dev/null; then
    echo "[$RUN_ID] WARNING: Could not fetch from origin (network issue?)" >> "$SUMMARY_LOG"
    # Continue anyway - might be offline
  fi

  # Check for divergence between local and remote
  local local_sha=$(git rev-parse HEAD 2>/dev/null)
  local remote_sha=$(git rev-parse "origin/$branch" 2>/dev/null || echo "")

  if [[ -n "$remote_sha" && "$local_sha" != "$remote_sha" ]]; then
    # Determine divergence type using merge-base
    local base=$(git merge-base HEAD "origin/$branch" 2>/dev/null || echo "")

    if [[ "$base" == "$remote_sha" ]]; then
      # Local is ahead of remote - this is OK (unpushed commits)
      echo "[$RUN_ID] INFO: Local is ahead of origin (unpushed commits exist)" >> "$SUMMARY_LOG"
    elif [[ "$base" == "$local_sha" ]]; then
      # Local is behind remote - fast-forward pull
      echo "[$RUN_ID] INFO: Pulling latest from origin (fast-forward)..." >> "$SUMMARY_LOG"
      if ! git pull --ff-only origin "$branch" 2>/dev/null; then
        echo "[$RUN_ID] ERROR: Fast-forward pull failed" >> "$FAILURES_LOG"
        exit 1
      fi
    else
      # Branches have diverged - cannot auto-resolve
      echo "[$RUN_ID] ERROR: Branch has diverged from origin. Manual resolution required." >> "$FAILURES_LOG"
      echo "[$RUN_ID]   Local:  $local_sha" >> "$FAILURES_LOG"
      echo "[$RUN_ID]   Remote: $remote_sha" >> "$FAILURES_LOG"
      echo "[$RUN_ID]   Base:   $base" >> "$FAILURES_LOG"
      exit 1
    fi
  fi

  echo "[$RUN_ID] INFO: Git pre-flight checks passed" >> "$SUMMARY_LOG"
}

pre_flight_git_check

# Emit preflight passed event
emit_event "preflight_passed" "target_dir" "$TARGET_DIR" "budget" "$MAX_BUDGET_USD"

# Verify claude CLI is available
if ! command -v claude &>/dev/null; then
  echo "[$RUN_ID] ERROR: Claude CLI not found in PATH" >> "$FAILURES_LOG"
  exit 1
fi

# Verify gh CLI is available (needed for GitHub operations)
if ! command -v gh &>/dev/null; then
  echo "[$RUN_ID] WARNING: gh CLI not found, GitHub operations will fail" >> "$SUMMARY_LOG"
fi

# Verify orchestrator prompt exists
if [[ ! -r "$PROMPT_FILE" ]]; then
  echo "[$RUN_ID] ERROR: Orchestrator prompt not found at $PROMPT_FILE. Please ensure the file exists. If you are using Nix, run 'darwin-rebuild switch --flake .' (for macOS) or 'home-manager switch' (for home-manager only) to deploy required files." >> "$FAILURES_LOG"
  exit 1
fi

# Check if Python notifier is available
SLACK_ENABLED=false
if [[ -n "$SLACK_CHANNEL" ]] && [[ -x "$NOTIFIER" ]] && command -v python3 &>/dev/null; then
  SLACK_ENABLED=true
fi

# --- ORCHESTRATOR PROMPT ---
ORCHESTRATOR_PROMPT=$(<"$PROMPT_FILE")

# --- SLACK: RUN STARTED ---
PARENT_TS=""
if [[ "$SLACK_ENABLED" == "true" ]]; then
  PARENT_TS=$(python3 "$NOTIFIER" run_started \
    --repo "$REPO_NAME" \
    --budget "$MAX_BUDGET_USD" \
    --run-id "$RUN_ID" \
    --channel "$SLACK_CHANNEL" 2>/dev/null) || true
fi

# --- EXECUTION ---
echo "" >> "$SUMMARY_LOG"
echo "=== [$RUN_ID] Starting: $REPO_NAME ===" >> "$SUMMARY_LOG"
echo "    Target: $TARGET_DIR" >> "$SUMMARY_LOG"
echo "    Budget: \$${MAX_BUDGET_USD}" >> "$SUMMARY_LOG"
[[ -n "$PARENT_TS" ]] && echo "    Slack thread: $PARENT_TS" >> "$SUMMARY_LOG"

# Emit run_started event for monitoring
emit_event "run_started" "budget" "$MAX_BUDGET_USD" "slack_enabled" "$SLACK_ENABLED"
START_TIME=$(date +%s)

set +e
# Use gtimeout (macOS via coreutils) or timeout (Linux), fallback to no timeout
TIMEOUT_CMD=""
if command -v gtimeout &>/dev/null; then
  TIMEOUT_CMD="gtimeout 3600"
elif command -v timeout &>/dev/null; then
  TIMEOUT_CMD="timeout 3600"
fi

$TIMEOUT_CMD claude -p "$ORCHESTRATOR_PROMPT" \
  --output-format stream-json \
  --verbose \
  --permission-mode bypassPermissions \
  --max-budget-usd "$MAX_BUDGET_USD" \
  --no-session-persistence \
  2>&1 | tee "$LOG_FILE"

# Capture exit code from the claude command in the pipeline
# This is a zsh script (per shebang), so use pipestatus (1-indexed)
# pipestatus[1] is the first command (timeout/claude), pipestatus[2] would be tee
EXIT_CODE=${pipestatus[1]}
set -e

# --- POST-RUN PROCESSING ---
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
END_TIME=$(date +%s)
DURATION_SEC=$((END_TIME - START_TIME))
DURATION_MIN=$((DURATION_SEC / 60))

# Check context usage for monitoring (optional tracking)
check_context_usage

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "=== [$TIMESTAMP] Completed: $REPO_NAME (exit 0) ===" >> "$SUMMARY_LOG"
  emit_event "run_completed" \
    "exit_code" "0" \
    "duration_sec" "$DURATION_SEC" \
    "duration_min" "$DURATION_MIN" \
    "status" "success"
else
  echo "=== [$TIMESTAMP] Failed: $REPO_NAME (exit $EXIT_CODE) ===" >> "$SUMMARY_LOG"
  echo "[$RUN_ID] $REPO_NAME: Exit code $EXIT_CODE" >> "$FAILURES_LOG"
  emit_event "run_completed" \
    "exit_code" "$EXIT_CODE" \
    "duration_sec" "$DURATION_SEC" \
    "duration_min" "$DURATION_MIN" \
    "status" "failed"
fi

# --- SLACK: RUN COMPLETED ---
if [[ "$SLACK_ENABLED" == "true" ]] && [[ -n "$PARENT_TS" ]]; then
  python3 "$NOTIFIER" run_completed \
    --repo "$REPO_NAME" \
    --channel "$SLACK_CHANNEL" \
    --thread-ts "$PARENT_TS" \
    --budget "$MAX_BUDGET_USD" \
    --run-id "$RUN_ID" \
    --log-file "$LOG_FILE" 2>/dev/null || true
fi

# --- UPDATE CONTROL FILE WITH LAST RUN (only on success) ---
if [[ $EXIT_CODE -eq 0 ]] && [[ -f "$CONTROL_FILE" ]]; then
  LAST_RUN_TS=$(date "+%Y-%m-%dT%H:%M:%S")
  CTRL_TMP=$(mktemp) || { echo "Warning: could not create temporary file for last_run update." >&2; }
  if [[ -n "$CTRL_TMP" ]]; then
    jq ".last_run = \"$LAST_RUN_TS\" | .last_run_repo = \"$REPO_NAME\"" "$CONTROL_FILE" > "$CTRL_TMP" && mv "$CTRL_TMP" "$CONTROL_FILE"
  fi
fi

echo "" >> "$SUMMARY_LOG"

# --- UPDATE CONTROL FILE ---
update_last_run "$REPO_NAME"

exit "$EXIT_CODE"
