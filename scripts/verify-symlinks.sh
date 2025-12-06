#!/usr/bin/env bash
# Verify home-manager symlinks are valid
# Usage: ./scripts/verify-symlinks.sh <path-to-home-files>

set -euo pipefail

HM_FILES="${1:-result-hm/home-files}"
ERRORS=0

echo "Checking Agent OS commands..."
for cmd in plan-product shape-spec write-spec create-tasks implement-tasks orchestrate-tasks improve-skills; do
  if [ -L "$HM_FILES/.claude/commands/$cmd.md" ]; then
    if [ -e "$HM_FILES/.claude/commands/$cmd.md" ]; then
      echo "  ✓ $cmd.md"
    else
      echo "  ✗ $cmd.md symlink broken"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  - $cmd.md not found (Agent OS may be disabled)"
  fi
done

echo ""
echo "Checking Agent OS agents..."
for agent in product-planner spec-initializer spec-shaper spec-verifier spec-writer tasks-list-creator implementer implementation-verifier; do
  if [ -L "$HM_FILES/.claude/agents/$agent.md" ]; then
    if [ -e "$HM_FILES/.claude/agents/$agent.md" ]; then
      echo "  ✓ $agent.md"
    else
      echo "  ✗ $agent.md symlink broken"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  - $agent.md not found (Agent OS may be disabled)"
  fi
done

echo ""
echo "Checking Claude settings..."
if [ -f "$HM_FILES/.claude/settings.json" ]; then
  jq . "$HM_FILES/.claude/settings.json" > /dev/null
  echo "  ✓ settings.json valid"
else
  echo "  ✗ settings.json not found"
  ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "Found $ERRORS errors"
  exit 1
fi
echo ""
echo "All checks passed"
