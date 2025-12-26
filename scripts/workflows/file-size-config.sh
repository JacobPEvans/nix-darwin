#!/usr/bin/env bash
# File Size Check Configuration
# Single source of truth for both pre-commit and GitHub Actions
#
# This file is sourced by:
# - scripts/workflows/check-file-sizes.sh (when no args provided)
# - .github/workflows/_file-size.yml (reads these values)

# Extended limit files (32KB max instead of 12KB)
# These are large documentation files that need more space
# Note: CLAUDE.md and .github/copilot-instructions.md are symlinks to AGENTS.md
FILE_SIZE_EXTENDED="AGENTS ANTHROPIC-ECOSYSTEM TROUBLESHOOTING"

# Exempt files (no limit)
# These are reference files that may grow indefinitely
FILE_SIZE_EXEMPT="RUNBOOK copilot-permissions-allow copilot-permissions-ask copilot-permissions-deny gemini-permissions-allow gemini-permissions-deny"

# Export for use by other scripts
export FILE_SIZE_EXTENDED
export FILE_SIZE_EXEMPT
