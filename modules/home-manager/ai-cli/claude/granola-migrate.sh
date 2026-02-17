#!/usr/bin/env zsh
# granola-migrate.sh - Triggered by watchexec when new .md files appear in granola/
#
# Environment variables (set by launchd):
#   VAULT_PATH     - Absolute path to the Obsidian vault
#   CLAUDE_MODEL   - Claude model to use (e.g., "sonnet")
#   CLAUDE_MAX_TURNS - Max conversation turns
#   MAX_BUDGET     - Max USD per invocation
#   DAILY_CAP      - Max cumulative USD per day
#   LOG_DIR        - Directory for log files
#   API_KEY_HELPER - Path to API key helper script (optional)

set -euo pipefail

# Validate required environment variables
for var in VAULT_PATH CLAUDE_MODEL CLAUDE_MAX_TURNS MAX_BUDGET DAILY_CAP LOG_DIR; do
  if [[ -z "${(P)var-}" ]]; then
    echo "$(date -Iseconds) ERROR: Required variable $var is not set" >&2
    exit 1
  fi
done

# ─── Section 1: Lock check ───────────────────────────────────────────────────

LOCK_DIR="${HOME}/.claude/locks"
LOCK_FILE="${LOCK_DIR}/granola-migrate.lock"
mkdir -p "$LOCK_DIR"

# Use mkdir for atomic lock creation (POSIX-safe, no TOCTOU race)
if ! mkdir "$LOCK_FILE" 2>/dev/null; then
  echo "$(date -Iseconds) Migration already running, skipping"
  exit 0
fi

cleanup() { rmdir "$LOCK_FILE" 2>/dev/null || true; }
trap cleanup EXIT

# ─── Section 2: Budget check ─────────────────────────────────────────────────

BUDGET_FILE="${LOG_DIR}/granola-budget.json"
mkdir -p "$LOG_DIR"
TODAY=$(date +%Y-%m-%d)

if [[ -f "$BUDGET_FILE" ]]; then
  budget_date=$(jq -r '.date // ""' "$BUDGET_FILE" 2>/dev/null || echo "")
  spent=$(jq -r '.spent // 0' "$BUDGET_FILE" 2>/dev/null || echo "0")

  if [[ "$budget_date" != "$TODAY" ]]; then
    echo "$(date -Iseconds) New day, resetting budget"
    echo "{\"date\":\"${TODAY}\",\"spent\":0.00}" > "$BUDGET_FILE"
    spent="0"
  fi
else
  echo "{\"date\":\"${TODAY}\",\"spent\":0.00}" > "$BUDGET_FILE"
  spent="0"
fi

# Compare as integers (cents) to avoid floating point issues
spent_cents=$(printf "%.0f" "$(echo "$spent * 100" | bc)")
cap_cents=$(printf "%.0f" "$(echo "${DAILY_CAP} * 100" | bc)")

if (( spent_cents >= cap_cents )); then
  echo "$(date -Iseconds) Daily budget exhausted (\$${spent} / \$${DAILY_CAP}), skipping"
  exit 0
fi

# ─── Section 3: Find unprocessed files ────────────────────────────────────────

cd "$VAULT_PATH"

UNPROCESSED=()
for file in granola/*/*.md(N); do
  # Skip transcripts
  [[ "$file" == *-transcript.md ]] && continue

  # Extract granola_id from frontmatter
  granola_id=$(grep -m1 '^granola_id:' "$file" 2>/dev/null | sed 's/^granola_id:[[:space:]]*//' || echo "")
  [[ -z "$granola_id" ]] && continue

  # Check if this granola_id exists anywhere else in the vault (outside granola/)
  existing=$(grep -rl "^granola_id: ${granola_id}" --include="*.md" . 2>/dev/null \
    | grep -v "^./granola/" \
    | head -1 || echo "")

  if [[ -z "$existing" ]]; then
    UNPROCESSED+=("$file")
  fi
done

if (( ${#UNPROCESSED[@]} == 0 )); then
  echo "$(date -Iseconds) No unprocessed files found"
  exit 0
fi

echo "$(date -Iseconds) Found ${#UNPROCESSED[@]} unprocessed file(s):"
printf '  %s\n' "${UNPROCESSED[@]}"

# ─── Section 4: Invoke Claude ─────────────────────────────────────────────────

# Build file list for prompt
FILE_LIST=""
for f in "${UNPROCESSED[@]}"; do
  FILE_LIST="${FILE_LIST}\n- ${f}"
done

PROMPT="You are running as an automated Granola migration agent. This is headless - NEVER prompt for user input.

Read .claude/skills/granola-merger/SKILL.md and execute the workflow for these unprocessed files:
${FILE_LIST}

CONSTRAINTS:
1. Process ONLY the listed files
2. Skip ambiguous files (unknown company) - log why
3. Skip duplicate audit phase and ambiguity resolution (no user available)
4. Create person pages only when company is auto-detectable
5. Commit to main and push
6. If nothing can be processed, exit cleanly"

# Calculate effective budget (remaining daily budget or per-run max, whichever is lower)
remaining=$(echo "${DAILY_CAP} - ${spent}" | bc)
effective_budget=$(echo "if (${MAX_BUDGET} < ${remaining}) ${MAX_BUDGET} else ${remaining}" | bc)

LOG_FILE="${LOG_DIR}/granola-migrate-$(date +%Y%m%d-%H%M%S).log"

echo "$(date -Iseconds) Invoking Claude (model=${CLAUDE_MODEL}, budget=\$${effective_budget}, turns=${CLAUDE_MAX_TURNS})"

# Temporarily disable pipefail so set -e doesn't abort on Claude failure;
# capture Claude's exit code from zsh's pipestatus array for budget accounting.
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

echo "$(date -Iseconds) Claude exited with code ${CLAUDE_EXIT}"

# ─── Section 5: Update budget ─────────────────────────────────────────────────

# Only charge full budget on success; minimal charge on failure
if (( CLAUDE_EXIT == 0 )); then
  budget_increment="${effective_budget}"
else
  # On failure, charge 10% as conservative estimate for partial work
  budget_increment=$(echo "${effective_budget} * 0.1" | bc)
fi

new_spent=$(echo "${spent} + ${budget_increment}" | bc)
echo "{\"date\":\"${TODAY}\",\"spent\":${new_spent}}" > "$BUDGET_FILE"
echo "$(date -Iseconds) Budget updated: \$${new_spent} / \$${DAILY_CAP} (charged \$${budget_increment})"
