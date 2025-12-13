#!/usr/bin/env zsh

# =============================================================================
# Auto-Claude: Autonomous AI Maintenance Daemon
# =============================================================================
# Runs Claude autonomously via launchd to perform maintenance tasks on git repos.
# Designed for full autonomy with safety constraints and structured logging.
#
# Usage: auto-claude.sh <target_dir> <max_budget_usd> [log_dir]
#
# Arguments:
# - target_dir     : Directory to run maintenance in (required)
# - max_budget_usd : Maximum cost per run in USD (required)
# - log_dir        : Directory for log files (optional, defaults to ~/.claude/logs)
# =============================================================================

set -euo pipefail

# --- ARGUMENT PARSING ---
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <target_dir> <max_budget_usd> [log_dir]" >&2
  exit 1
fi

TARGET_DIR="$1"
MAX_BUDGET_USD="$2"
LOG_DIR="${3:-$HOME/.claude/logs}"

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
# Only source if files exist and are readable; use || true to prevent set -e exit
[[ -r "$HOME/.zshrc" ]] && source "$HOME/.zshrc" 2>/dev/null || true
[[ -r "$HOME/.profile" ]] && source "$HOME/.profile" 2>/dev/null || true

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

# --- ORCHESTRATOR PROMPT ---
ORCHESTRATOR_PROMPT='You are an autonomous maintenance agent running unattended via launchd in a git repository.

CONSTRAINTS:
- No user interaction possible. If blocked, log the issue and move on to the next task.
- Time budget: ~1 hour max. Prefer quick wins over deep work.
- Safety: NEVER force-push, delete branches, merge PRs, or modify protected files.
- All PRs should be left open for human review - do not merge.

PHASE 1 - RECONNAISSANCE (5 min max):
Gather current state by running these commands:
- git status
- git log --oneline -10
- git branch -a
- gh issue list --limit 20 --state open (if gh available)
- gh pr list --state open (if gh available)
- For any open PRs: gh pr checks <number>

PHASE 2 - TASK SELECTION:
From reconnaissance, select tasks from this priority list (highest first):
1. Fix failing CI checks on open PRs (analyze failure, fix code, push)
2. Respond to PR review comments (use gh pr view to see comments)
3. Address GitHub Issues labeled "good first issue" or "bug"
4. Fix obvious typos/errors in documentation or comments
5. Close stale issues that appear already resolved
6. Improve test coverage for uncovered code paths
7. Update outdated documentation

Select multiple small tasks if time permits. Prefer breadth over depth.

PHASE 3 - EXECUTION:
For each task:
- Create a feature branch (never work on main)
- Make atomic, focused changes
- Write clear commit messages
- Push and create PR with descriptive title/body
- Do NOT merge - leave for human review
- Move to next task

PHASE 4 - SUMMARY:
When done (or time/budget exhausted), output a structured summary:
{
  "run_id": "<timestamp>",
  "repository": "<repo_name>",
  "duration_minutes": <number>,
  "tasks_identified": ["task1", "task2", ...],
  "tasks_completed": ["task1", ...],
  "tasks_blocked": [{"task": "...", "reason": "..."}],
  "prs_created": ["#123", ...],
  "outcome": "success|partial|no_tasks|blocked",
  "notes": "any additional context"
}

IMPORTANT BEHAVIORS:
- If you encounter rate limits, wait briefly and retry once, then move on.
- If a task is too complex, create an issue describing the problem instead.
- Prefer creating small, reviewable PRs over large changes.
- Always check if a branch/PR already exists before creating duplicates.
- Use git worktrees if you need to work on multiple branches simultaneously.'

# --- EXECUTION ---
echo "" >> "$SUMMARY_LOG"
echo "=== [$RUN_ID] Starting: $REPO_NAME ===" >> "$SUMMARY_LOG"
echo "    Target: $TARGET_DIR" >> "$SUMMARY_LOG"
echo "    Budget: \$${MAX_BUDGET_USD}" >> "$SUMMARY_LOG"

claude -p "$ORCHESTRATOR_PROMPT" \
  --output-format stream-json \
  --verbose \
  --permission-mode bypassPermissions \
  --max-budget-usd "$MAX_BUDGET_USD" \
  --no-session-persistence \
  2>&1 | tee "$LOG_FILE"

EXIT_CODE=${pipestatus[1]}

# --- POST-RUN PROCESSING ---
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Extract final summary from log if present (using jq for proper JSON parsing)
if command -v jq &>/dev/null; then
  FINAL_SUMMARY=$(jq -c 'select(.outcome)' "$LOG_FILE" 2>/dev/null | tail -1)
else
  echo "[$RUN_ID] WARNING: jq not found, cannot extract structured summary" >> "$SUMMARY_LOG"
  FINAL_SUMMARY=""
fi

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "=== [$TIMESTAMP] Completed: $REPO_NAME (exit 0) ===" >> "$SUMMARY_LOG"
else
  echo "=== [$TIMESTAMP] Failed: $REPO_NAME (exit $EXIT_CODE) ===" >> "$SUMMARY_LOG"
  echo "[$RUN_ID] $REPO_NAME: Exit code $EXIT_CODE" >> "$FAILURES_LOG"
fi

if [[ -n "$FINAL_SUMMARY" ]]; then
  echo "    Summary: $FINAL_SUMMARY" >> "$SUMMARY_LOG"
fi
echo "" >> "$SUMMARY_LOG"

exit $EXIT_CODE
