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
# =============================================================================

set -euo pipefail

# --- ARGUMENT PARSING ---
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <target_dir> <max_budget_usd> [log_dir] [slack_channel]" >&2
  exit 1
fi

TARGET_DIR="$1"
MAX_BUDGET_USD="$2"
LOG_DIR="${3:-$HOME/.claude/logs}"
SLACK_CHANNEL="${4:-}"

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

# --- PRE-FLIGHT CHECKS ---
cd "$TARGET_DIR" || {
  echo "[$RUN_ID] ERROR: Cannot cd to $TARGET_DIR" >> "$FAILURES_LOG"
  exit 1
}

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
  echo "[$RUN_ID] ERROR: Orchestrator prompt not found at $PROMPT_FILE. Please ensure the file exists. If you are using Nix, run 'nix rebuild' to deploy required files." >> "$FAILURES_LOG"
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

# Capture exit code from the pipeline (zsh uses pipestatus, bash uses PIPESTATUS)
if [[ -n "${pipestatus+x}" ]]; then
  EXIT_CODE=${pipestatus[1]}
elif [[ -n "${PIPESTATUS+x}" ]]; then
  EXIT_CODE=${PIPESTATUS[0]}
else
  EXIT_CODE=$?
fi
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

exit "$EXIT_CODE"
