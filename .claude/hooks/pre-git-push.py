#!/usr/bin/env python3
"""
Pre-git-push hook: Requires darwin-rebuild before pushing.

This hook runs before Bash commands. If it's a git push,
it runs darwin-rebuild first and blocks the push if it fails.

Exit codes:
  0 = allow the command
  2 = block the command (shows stderr to Claude)
"""

import json
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
    if not ("git push" in command or command.startswith("git push")):
        return 0

    # Run darwin-rebuild
    print("\n" + "═" * 64)
    print("🔨 Pre-push: Running darwin-rebuild switch --flake .")
    print("═" * 64 + "\n", flush=True)

    result = subprocess.run(
        ["sudo", "darwin-rebuild", "switch", "--flake", "."],
        # Let output flow through naturally
    )

    if result.returncode != 0:
        print("\n" + "═" * 64)
        print("❌ darwin-rebuild failed! Push blocked.")
        print("═" * 64 + "\n", file=sys.stderr)
        return 2  # Block the push

    print("\n" + "═" * 64)
    print("✅ Pre-push checks passed")
    print("═" * 64 + "\n", flush=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())
