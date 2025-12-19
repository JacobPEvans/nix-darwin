#!/usr/bin/env python3
"""
Pre-git-push hook: Requires darwin-rebuild before pushing.

This hook runs before Bash commands. If it's a git push,
it runs darwin-rebuild first and blocks the push if it fails.

Exit codes:
  0 = allow the command
  2 = block the command (shows stderr to Claude)

Input: JSON from stdin with tool_input.command containing the Bash command
Output: Exit code determines whether command proceeds
"""

import json
import os
import subprocess
import sys


def main():
    # Read hook input from stdin
    try:
        hook_input = json.load(sys.stdin)
    except json.JSONDecodeError:
        # No valid input, allow command
        return 0

    # Get the command being executed
    command = hook_input.get("tool_input", {}).get("command", "")

    # Only act on git push commands
    if "git push" not in command:
        return 0

    # Skip darwin-rebuild in CI/automated workflows
    ci_markers = ["CI", "GITHUB_ACTIONS", "AUTOMATED_WORKFLOW", "AUTO_CLAUDE"]
    is_automated = any(os.environ.get(marker) for marker in ci_markers)

    if is_automated:
        print("\n" + "═" * 64)
        print("⚠️  Pre-push: Automated workflow detected, skipping darwin-rebuild")
        print("    CI will perform full build verification")
        print("═" * 64 + "\n", flush=True)
        return 0

    # Run darwin-rebuild build (dry-run, no system changes)
    print("\n" + "═" * 64)
    print("🔨 Pre-push: Validating build with darwin-rebuild...")
    print("═" * 64 + "\n", flush=True)

    try:
        result = subprocess.run(
            ["darwin-rebuild", "build", "--flake", "."],
            check=True,
            capture_output=True,
            text=True,
            timeout=600,
        )
        print("✅ darwin-rebuild build succeeded\n", flush=True)
        return 0
    except subprocess.TimeoutExpired:
        print("\n" + "═" * 64, file=sys.stderr)
        print("❌ Pre-push BLOCKED: darwin-rebuild timed out (>10 minutes)", file=sys.stderr)
        print("    Run manually: darwin-rebuild build --flake .", file=sys.stderr)
        print("═" * 64 + "\n", file=sys.stderr, flush=True)
        return 2
    except subprocess.CalledProcessError as e:
        print("\n" + "═" * 64, file=sys.stderr)
        print("❌ Pre-push BLOCKED: darwin-rebuild build failed", file=sys.stderr)
        print("    Fix the build errors before pushing:", file=sys.stderr)
        print(e.stderr, file=sys.stderr)
        print("═" * 64 + "\n", file=sys.stderr, flush=True)
        return 2
    except FileNotFoundError:
        print("\n" + "═" * 64, file=sys.stderr)
        print("⚠️  Pre-push WARNING: darwin-rebuild not found", file=sys.stderr)
        print("    Skipping validation (non-Darwin system?)", file=sys.stderr)
        print("═" * 64 + "\n", file=sys.stderr, flush=True)
        return 0


if __name__ == "__main__":
    sys.exit(main())
