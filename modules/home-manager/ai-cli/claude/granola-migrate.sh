#!/usr/bin/env zsh
# granola-migrate.sh - Triggered by watchexec when new .md files appear in granola/
#
# Required environment variables (set by launchd):
#   VAULT_PATH, CLAUDE_MODEL, CLAUDE_MAX_TURNS, MAX_BUDGET, DAILY_CAP, LOG_DIR

# Restore homebrew PATH stripped by nix-darwin /etc/zshenv
export PATH="/opt/homebrew/bin:$PATH"

set -euo pipefail

log() { echo "$(date -Iseconds) $*"; }

# Validate required environment variables
for var in VAULT_PATH CLAUDE_MODEL CLAUDE_MAX_TURNS MAX_BUDGET DAILY_CAP LOG_DIR; do
  if [[ -z "${(P)var-}" ]]; then
    log "ERROR: Required variable $var is not set" >&2
    exit 1
  fi
done

# --- Lock (atomic mkdir, no TOCTOU race) ---

LOCK_FILE="${HOME}/.claude/locks/granola-migrate.lock"
mkdir -p "${LOCK_FILE:h}"

if ! mkdir "$LOCK_FILE" 2>/dev/null; then
  log "Migration already running, skipping"
  exit 0
fi
trap 'rmdir "$LOCK_FILE" 2>/dev/null || true' EXIT

# --- Daily budget gate ---

BUDGET_FILE="${LOG_DIR}/granola-budget.json"
mkdir -p "$LOG_DIR"
TODAY=$(date +%Y-%m-%d)

# Reset budget on new day or missing file
if [[ -f "$BUDGET_FILE" ]] && [[ "$(jq -r '.date // ""' "$BUDGET_FILE" 2>/dev/null)" == "$TODAY" ]]; then
  spent=$(jq -r '.spent // 0' "$BUDGET_FILE" 2>/dev/null || echo "0")
else
  spent="0"
  echo "{\"date\":\"${TODAY}\",\"spent\":0.00}" > "$BUDGET_FILE"
fi

# Compare as integer cents to avoid floating-point issues
spent_cents=$(printf "%.0f" "$(echo "$spent * 100" | bc)")
cap_cents=$(printf "%.0f" "$(echo "$DAILY_CAP * 100" | bc)")

if (( spent_cents >= cap_cents )); then
  log "Daily budget exhausted (\$${spent}/\$${DAILY_CAP}), skipping"
  exit 0
fi

# --- Find unprocessed granola files ---

cd "$VAULT_PATH"

UNPROCESSED=()
for file in granola/*/*.md(N); do
  [[ "$file" == *-transcript.md ]] && continue

  granola_id=$(grep -m1 '^granola_id:' "$file" 2>/dev/null | sed 's/^granola_id:[[:space:]]*//' || echo "")
  [[ -z "$granola_id" ]] && continue

  # Check if already migrated (granola_id exists outside granola/)
  if ! grep -rql "^granola_id: ${granola_id}" --include="*.md" . 2>/dev/null | grep -qv "^./granola/"; then
    UNPROCESSED+=("$file")
  fi
done

if (( ${#UNPROCESSED[@]} == 0 )); then
  log "No unprocessed files found"
  exit 0
fi

log "Found ${#UNPROCESSED[@]} unprocessed file(s):"
printf '  %s\n' "${UNPROCESSED[@]}"

# --- Invoke Claude headless ---

FILE_LIST=$(printf '\n- %s' "${UNPROCESSED[@]}")

PROMPT="You are running as an automated Granola migration agent. Headless mode - NEVER prompt for user input.

Read .claude/skills/granola-merger/SKILL.md and process these files:
${FILE_LIST}

CONSTRAINTS:
1. Process ONLY the listed files
2. Skip ambiguous files and phases requiring user input
3. Create person pages only when company is auto-detectable
4. Commit to main and push"

# Effective budget: min(per-run max, remaining daily budget)
remaining=$(echo "$DAILY_CAP - $spent" | bc)
effective_budget=$(echo "if ($MAX_BUDGET < $remaining) $MAX_BUDGET else $remaining" | bc)

LOG_FILE="${LOG_DIR}/granola-migrate-$(date +%Y%m%d-%H%M%S).log"
log "Invoking Claude (model=${CLAUDE_MODEL}, budget=\$${effective_budget}, turns=${CLAUDE_MAX_TURNS})"

# Capture Claude's exit code via pipestatus (disable pipefail temporarily)
set +o pipefail
claude -p "$PROMPT" \
  --model "$CLAUDE_MODEL" \
  --max-budget-usd "$effective_budget" \
  --max-turns "$CLAUDE_MAX_TURNS" \
  --output-format stream-json \
  --verbose \
  --no-session-persistence \
  2>&1 | tee "$LOG_FILE"
CLAUDE_EXIT=$pipestatus[1]
set -o pipefail

log "Claude exited with code ${CLAUDE_EXIT}"

# --- Update daily budget ---
# Claude's --max-budget-usd caps actual spending, so charge the full effective budget.
# This is conservative (may overcount) but simple and safe.

# Only charge budget on successful runs (exit 0) to avoid charging for failed/partial runs,
# including command-not-found and other non-zero exit codes.
if (( CLAUDE_EXIT == 0 )); then
  new_spent=$(echo "$spent + $effective_budget" | bc)
  echo "{\"date\":\"${TODAY}\",\"spent\":${new_spent}}" > "$BUDGET_FILE"
  log "Budget: \$${new_spent}/\$${DAILY_CAP} (charged \$${effective_budget})"
else
  log "Claude failed (exit ${CLAUDE_EXIT}), not charging budget"
fi
