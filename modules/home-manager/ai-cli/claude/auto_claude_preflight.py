#!/usr/bin/env python3
"""
Auto-Claude Preflight Checks

Handles pre-run validation:
- Control file (pause/skip) checks
- Slack channel resolution
- Git repository state validation

Usage:
    python3 auto_claude_preflight.py check-control
    python3 auto_claude_preflight.py resolve-channel <target_dir>
    python3 auto_claude_preflight.py check-git <target_dir>
    python3 auto_claude_preflight.py all <target_dir>  # Run all checks

Exit codes:
    0 = OK to proceed
    1 = Error (should not run)
    2 = Skip (paused or skip_count > 0)
"""

import argparse
import glob
import json
import os
import subprocess
import sys
import time
from pathlib import Path

from auto_claude_utils import (
    get_keychain_password,
    get_repo_name,
    iso_to_epoch,
    load_bws_env,
    sanitize_repo_name,
)

CONTROL_FILE = Path.home() / ".claude/auto-claude-control.json"


def check_control_file(force_run: bool = False) -> dict:
    """Check control file for pause/skip states. Returns status dict."""
    result = {"should_run": True, "reason": None, "skip_count": 0}

    if force_run:
        return result

    if not CONTROL_FILE.exists():
        return result

    try:
        control = json.loads(CONTROL_FILE.read_text())
    except (json.JSONDecodeError, OSError):
        return result

    # Check pause_until
    pause_until = control.get("pause_until")
    if pause_until:
        pause_epoch = iso_to_epoch(pause_until)
        if pause_epoch and time.time() < pause_epoch:
            result["should_run"] = False
            result["reason"] = f"Paused until {pause_until}"
            return result

    # Check skip_count
    skip_count = control.get("skip_count", 0)
    if isinstance(skip_count, int) and skip_count > 0:
        # Decrement skip count
        control["skip_count"] = skip_count - 1
        try:
            CONTROL_FILE.write_text(json.dumps(control, indent=2))
        except OSError:
            pass
        result["should_run"] = False
        result["reason"] = f"Skip count was {skip_count}, now {skip_count - 1}"
        result["skip_count"] = skip_count - 1
        return result

    return result


def resolve_slack_channel(target_dir: str) -> dict:
    """Resolve Slack channel for a repository. Returns channel info."""
    config = load_bws_env()
    bws_account = config.get("BWS_KEYCHAIN_ACCOUNT")

    repo_name = get_repo_name(target_dir)
    sanitized = sanitize_repo_name(repo_name)
    keychain_key = f"SLACK_CHANNEL_ID_{sanitized}"

    # Try repo-specific channel
    channel = get_keychain_password(keychain_key, bws_account)
    if channel:
        return {
            "channel": channel,
            "source": "keychain",
            "repo_name": repo_name,
            "keychain_key": keychain_key,
        }

    # Try fallback
    fallback = config.get("SLACK_DEFAULT_CHANNEL")
    if fallback:
        return {
            "channel": fallback,
            "source": "fallback",
            "repo_name": repo_name,
            "keychain_key": keychain_key,
        }

    return {
        "channel": None,
        "source": "none",
        "repo_name": repo_name,
        "keychain_key": keychain_key,
    }


def check_git_status(target_dir: str) -> dict:
    """Check git repository state. Returns status dict."""
    result = {
        "ok": True,
        "branch": None,
        "clean": True,
        "synced": True,
        "message": "Git checks passed",
    }

    try:
        # Get current branch
        branch_result = subprocess.run(
            ["git", "-C", target_dir, "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
        result["branch"] = branch_result.stdout.strip()

        # Must be on main or master
        if result["branch"] not in ("main", "master"):
            result["ok"] = False
            result["message"] = f"Not on main/master branch (on: {result['branch']})"
            return result

        # Check for uncommitted changes
        status_result = subprocess.run(
            ["git", "-C", target_dir, "status", "--porcelain"],
            capture_output=True,
            text=True,
            check=True,
        )
        if status_result.stdout.strip():
            result["ok"] = False
            result["clean"] = False
            result["message"] = "Working tree has uncommitted changes"
            return result

        # Fetch latest
        subprocess.run(
            ["git", "-C", target_dir, "fetch", "origin", result["branch"], "--quiet"],
            capture_output=True,
            check=False,
        )

        # Check divergence
        local_sha = subprocess.run(
            ["git", "-C", target_dir, "rev-parse", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()

        remote_sha_result = subprocess.run(
            ["git", "-C", target_dir, "rev-parse", f"origin/{result['branch']}"],
            capture_output=True,
            text=True,
            check=False,
        )
        remote_sha = remote_sha_result.stdout.strip() if remote_sha_result.returncode == 0 else None

        if remote_sha and local_sha != remote_sha:
            base_result = subprocess.run(
                ["git", "-C", target_dir, "merge-base", "HEAD", f"origin/{result['branch']}"],
                capture_output=True,
                text=True,
                check=False,
            )
            base = base_result.stdout.strip() if base_result.returncode == 0 else None

            if base == remote_sha:
                result["message"] = "Local is ahead of origin (unpushed commits)"
            elif base == local_sha:
                result["message"] = "Local is behind origin (needs pull)"
                result["needs_pull"] = True
            else:
                result["ok"] = False
                result["synced"] = False
                result["message"] = "Branch has diverged from origin"

    except subprocess.CalledProcessError:
        result["message"] = "Not a git repository or git unavailable"
        # Continue anyway - might not be a git repo

    return result


def check_stale_instance(target_dir: str) -> dict:
    """Check for stale auto-claude instances and kill them if inactive."""
    import glob
    import time

    repo_name = get_repo_name(target_dir)
    result = {"ok": True, "killed": False, "message": "No stale instance found"}

    try:
        # Find auto-claude processes for this repo
        ps_result = subprocess.run(
            ["pgrep", "-f", f"auto-claude.sh.*{target_dir}"],
            capture_output=True, text=True,
        )

        if ps_result.returncode != 0:
            # No running instance found
            return result

        pids = ps_result.stdout.strip().split("\n")
        current_pid = str(subprocess.run(["pgrep", "-P", "1", "auto-claude.sh"], capture_output=True, text=True).stdout.strip()) or "0"

        for pid in pids:
            if not pid or pid == current_pid:
                continue

            # Check if process is actually doing something
            has_recent_activity = False

            # Check recent log files (modified in last 1 hour = 3600 seconds)
            now = time.time()
            log_patterns = [
                f"{Path.home()}/.claude/logs/nix_*.jsonl",
                f"{Path.home()}/.claude/logs/launchd-*.log",
            ]

            for pattern in log_patterns:
                for log_file in glob.glob(pattern):
                    try:
                        mtime = os.path.getmtime(log_file)
                        if (now - mtime) < 3600:  # 1 hour
                            has_recent_activity = True
                            break
                    except OSError:
                        pass

            # Check recent git activity in target_dir (last 1 hour)
            if not has_recent_activity:
                try:
                    git_result = subprocess.run(
                        ["git", "-C", target_dir, "log", "--since=1 hour ago", "--oneline"],
                        capture_output=True, text=True, check=False,
                    )
                    if git_result.stdout.strip():
                        has_recent_activity = True
                except Exception:
                    pass

            # Check recent GitHub activity (PRs, issues, commits)
            if not has_recent_activity:
                try:
                    # Check for recent PR activity
                    pr_result = subprocess.run(
                        ["gh", "pr", "list", "--state", "all", "--limit", "5"],
                        cwd=target_dir, capture_output=True, text=True, check=False,
                    )
                    if pr_result.stdout.strip():
                        has_recent_activity = True
                except Exception:
                    pass

            if not has_recent_activity:
                # Kill the stale process
                try:
                    subprocess.run(["kill", pid], check=True)
                    result["killed"] = True
                    result["message"] = f"Killed stale auto-claude process (PID {pid}) with no recent activity"
                except subprocess.CalledProcessError:
                    pass

        return result

    except Exception as e:
        # Don't fail on stale check errors
        return {"ok": True, "killed": False, "message": f"Could not check stale instances: {str(e)}"}


def check_issue_limits(target_dir: str, force_run: bool = False) -> dict:
    """Check issue limits. At limit, skip issue creation but continue other work."""
    if force_run:
        return {"ok": True, "count": 0, "skip_issue_creation": False, "message": "Bypassed (force)"}

    try:
        result = subprocess.run(
            ["gh", "issue", "list", "--state", "open", "--label", "ai-created", "--json", "number"],
            cwd=target_dir, capture_output=True, text=True, check=True,
        )
        count = len(json.loads(result.stdout))
        if count >= 50:
            # Still return ok=True to allow auto-claude to continue, but signal to skip issues
            return {
                "ok": True,
                "count": count,
                "skip_issue_creation": True,
                "message": f"Issue limit reached ({count}/50). Skipping issue creation."
            }
        return {"ok": True, "count": count, "skip_issue_creation": False, "message": f"OK: {count} ai-created issues"}
    except Exception:
        # Don't block on gh errors - repo might not have issues
        return {"ok": True, "count": -1, "skip_issue_creation": False, "message": "Warning: gh check failed"}


def main():
    parser = argparse.ArgumentParser(description="Auto-Claude preflight checks")
    parser.add_argument("command", choices=["check-control", "resolve-channel", "check-git", "all"])
    parser.add_argument("target_dir", nargs="?", help="Target directory (required for some commands)")
    parser.add_argument("--force", action="store_true", help="Force run (bypass control file)")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    if args.command in ("resolve-channel", "check-git", "all") and not args.target_dir:
        parser.error(f"{args.command} requires target_dir")

    if args.command == "check-control":
        result = check_control_file(force_run=args.force)
        if args.json:
            print(json.dumps(result))
        else:
            if result["should_run"]:
                print("OK")
            else:
                print(f"SKIP: {result['reason']}")
        sys.exit(0 if result["should_run"] else 2)

    elif args.command == "resolve-channel":
        result = resolve_slack_channel(args.target_dir)
        if args.json:
            print(json.dumps(result))
        else:
            print(result.get("channel") or "")
        sys.exit(0)

    elif args.command == "check-git":
        result = check_git_status(args.target_dir)
        if args.json:
            print(json.dumps(result))
        else:
            print(result["message"])
        sys.exit(0 if result["ok"] else 1)

    elif args.command == "all":
        results = {
            "stale": check_stale_instance(args.target_dir),
            "control": check_control_file(force_run=args.force),
            "channel": resolve_slack_channel(args.target_dir),
            "git": check_git_status(args.target_dir),
            "issues": check_issue_limits(args.target_dir, force_run=args.force),
        }

        # Determine overall status
        if not results["control"]["should_run"]:
            results["status"] = "skip"
            results["reason"] = results["control"]["reason"]
        elif not results["git"]["ok"]:
            results["status"] = "error"
            results["reason"] = results["git"]["message"]
        else:
            results["status"] = "ok"
            results["reason"] = None
            # Note: issues check always returns ok=True, may set skip_issue_creation flag

        if args.json:
            print(json.dumps(results))
        else:
            print(f"Status: {results['status']}")
            if results["reason"]:
                print(f"Reason: {results['reason']}")
            print(f"Channel: {results['channel'].get('channel') or 'none'}")

        if results["status"] == "skip":
            sys.exit(2)
        elif results["status"] == "error":
            sys.exit(1)
        sys.exit(0)


if __name__ == "__main__":
    main()
