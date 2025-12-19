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
      # Note: LOG_DIR is passed as argument, SUMMARY_LOG defined at line 150
      local log_dir="${3:-$HOME/.claude/logs}"
      echo "[$(date +%Y%m%d_%H%M%S)] SKIPPED: Paused until $pause_until" >> "${log_dir}/summary.log"
      exit 0
    fi
  fi

  # Check skip_count
  local skip_count=$(jq -r '.skip_count // 0' "$CONTROL_FILE" 2>/dev/null)
  if [[ "$skip_count" -gt 0 ]] 2>/dev/null; then
    # Decrement skip count
    local tmp
    local log_dir="${3:-$HOME/.claude/logs}"
    tmp=$(mktemp) || {
      echo "[$(date +%Y%m%d_%H%M%S)] WARNING: Could not create temp file for skip_count update" >> "${log_dir}/summary.log"
      exit 0
    }
    if jq ".skip_count = $((skip_count - 1))" "$CONTROL_FILE" > "$tmp"; then
      mv "$tmp" "$CONTROL_FILE"
    else
      rm -f "$tmp"
    fi
    echo "[$(date +%Y%m%d_%H%M%S)] SKIPPED: Skip count was $skip_count, now $((skip_count - 1))" >> "${log_dir}/summary.log"
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

# --- ENVIRONMENT ---
# Source shell configs for full environment (API keys, PATH, git credentials)
# Required because launchd runs in a minimal shell
set +e
[[ -r "$HOME/.zshrc" ]] && source "$HOME/.zshrc" 2>/dev/null
[[ -r "$HOME/.profile" ]] && source "$HOME/.profile" 2>/dev/null
set -e

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

  # Ensure we are on an allowed branch.
  # Default allowed branches are "main" and "master", but this can be overridden
  # by setting CLAUDE_ALLOWED_BRANCHES to a space-separated list of branch names.
  local allowed_branches="${CLAUDE_ALLOWED_BRANCHES:-main master}"
  local branch_allowed=1
  for b in $allowed_branches; do
    if [[ "$branch" == "$b" ]]; then
      branch_allowed=0
      break
    fi
  done
  if (( branch_allowed != 0 )); then
    echo "[$RUN_ID] ERROR: Current branch '$branch' is not in allowed branches: $allowed_branches. Switch to an allowed branch first." >> "$FAILURES_LOG"
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

  if [[ -n "$remote_sha" ]]; then
    if [[ "$local_sha" == "$remote_sha" ]]; then
      # Branches are synchronized
      echo "[$RUN_ID] INFO: Local and origin are synchronized" >> "$SUMMARY_LOG"
    else
      # Branches differ - determine divergence type using merge-base
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
  fi

  # Ensure working tree is clean (no uncommitted changes)
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    echo "[$RUN_ID] ERROR: Working tree has uncommitted changes. Commit or stash them first." >> "$FAILURES_LOG"
    git status --short >> "$FAILURES_LOG"
    exit 1
  fi

  echo "[$RUN_ID] INFO: Git pre-flight checks passed" >> "$SUMMARY_LOG"
}

pre_flight_git_check

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

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "=== [$TIMESTAMP] Completed: $REPO_NAME (exit 0) ===" >> "$SUMMARY_LOG"
else
  echo "=== [$TIMESTAMP] Failed: $REPO_NAME (exit $EXIT_CODE) ===" >> "$SUMMARY_LOG"
  echo "[$RUN_ID] $REPO_NAME: Exit code $EXIT_CODE" >> "$FAILURES_LOG"
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

echo "" >> "$SUMMARY_LOG"

# --- UPDATE CONTROL FILE (only on success) ---
if [[ $EXIT_CODE -eq 0 ]]; then
  update_last_run "$REPO_NAME"
fi

exit "$EXIT_CODE"
