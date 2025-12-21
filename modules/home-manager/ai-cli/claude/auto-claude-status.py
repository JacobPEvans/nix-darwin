#!/usr/bin/env python3
"""SwiftBar Auto-Claude Status Plugin."""

import json
import shlex
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Optional

HOME = Path.home()
CONTROL_FILE = HOME / ".claude" / "auto-claude-control.json"
LOG_DIR = HOME / ".claude" / "logs"
CTL_SCRIPT = HOME / ".claude" / "scripts" / "auto-claude-ctl.sh"


def get_active_sessions() -> int:
    """Count running auto-claude sessions.

    Auto-claude runs: claude -p <prompt> --output-format stream-json ...
    We look for the specific --output-format flag used by auto-claude.
    """
    try:
        result = subprocess.run(
            ["pgrep", "-f", "claude.*--output-format stream-json"],
            capture_output=True,
            text=True,
        )
        return len(result.stdout.strip().split("\n")) if result.stdout.strip() else 0
    except Exception:
        return 0


def parse_iso_time(iso_str: str) -> Optional[datetime]:
    """Parse ISO timestamp."""
    try:
        return datetime.fromisoformat(iso_str.replace("Z", "+00:00"))
    except Exception:
        return None


def get_status() -> tuple[str, str, str]:
    """Return (icon, status_text, color)."""
    if not CONTROL_FILE.exists():
        return "🤖", "No control file", "gray"

    try:
        with open(CONTROL_FILE) as f:
            data = json.load(f)
    except Exception:
        return "⚠️", "Error reading control file", "red"

    active = get_active_sessions()
    if active > 0:
        return "🔄", f"Running ({active} sessions)", "blue"

    pause_until = data.get("pause_until")
    if pause_until:
        pause_time = parse_iso_time(pause_until)
        if pause_time:
            # Ensure `now` and `pause_time` are comparable (both naive or both aware)
            try:
                if pause_time.tzinfo is not None:
                    now = datetime.now(pause_time.tzinfo)
                else:
                    now = datetime.now()
                if now < pause_time:
                    return "⏸️", f"Paused until {pause_time.strftime('%H:%M')}", "orange"
            except Exception:
                # If anything goes wrong comparing times (e.g. unexpected tzinfo),
                # ignore the pause and fall through to the normal status logic.
                pass

    skip_count = data.get("skip_count", 0)
    if skip_count > 0:
        return "⏭️", f"Skipping {skip_count} runs", "yellow"

    return "🤖", "Active", "green"


def get_recent_logs(limit: int = 5) -> list[tuple[str, str, str]]:
    """Return [(name, size, path), ...] for recent logs."""
    if not LOG_DIR.exists():
        return []

    logs = sorted(LOG_DIR.glob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)
    result = []
    for log in logs[:limit]:
        size = log.stat().st_size
        if size > 1024 * 1024:
            size_str = f"{size / (1024 * 1024):.1f}MB"
        elif size > 1024:
            size_str = f"{size / 1024:.1f}KB"
        else:
            size_str = f"{size}B"
        result.append((log.stem, size_str, str(log)))
    return result


def main():
    icon, status, color = get_status()

    # Menu bar title
    print(icon)
    print("---")
    print("Auto-Claude Status | size=14")
    print(f"{status} | color={color}")
    print("---")

    # Control file info
    if CONTROL_FILE.exists():
        try:
            with open(CONTROL_FILE) as f:
                data = json.load(f)
            last_run = data.get("last_run", "never")
            last_repo = data.get("last_run_repo", "unknown")
            print(f"Last run: {last_run}")
            print(f"Repo: {last_repo}")
        except Exception:
            print("Last run: error | color=red")
    else:
        print("Last run: never | color=gray")

    print("---")

    # Recent logs
    print("Recent Logs | size=12")
    logs = get_recent_logs()
    if logs:
        for name, size, path in logs:
            # Properly escape path for shell safety
            escaped_path = shlex.quote(path)
            print(f"  {name} ({size}) | bash='open -R {escaped_path}' terminal=false")
    else:
        print("  No logs found | color=gray")

    print("---")

    # Actions - escape paths to prevent potential shell injection
    ctl = shlex.quote(str(CTL_SCRIPT))
    log_dir = shlex.quote(str(LOG_DIR))
    print("Actions | size=12")
    print(f"  Resume | bash={ctl} param1='resume' terminal=false refresh=true")
    # Pause duration submenu with multiple options
    print("--Pause Duration")
    for hours in [1, 2, 4, 6, 8, 12]:
        label = f"{hours} hour" if hours == 1 else f"{hours} hours"
        print(f"----{label} | bash={ctl} param1='pause' param2='{hours}' terminal=false refresh=true")
    # Calculate hours until midnight for "pause until midnight" option
    now = datetime.now()
    midnight = now.replace(hour=23, minute=59, second=59, microsecond=0)
    hours_until_midnight = max(1, int((midnight - now).total_seconds() / 3600) + 1)
    print(f"----Until midnight | bash={ctl} param1='pause' param2='{hours_until_midnight}' terminal=false refresh=true")
    print(f"--Skip next run | bash={ctl} param1='skip' param2='1' terminal=false refresh=true")
    print("---")
    print(f"  Run Now... | bash={ctl} param1='run' terminal=true")
    print("---")
    print(f"Open Logs Folder | bash='open {log_dir}' terminal=false")
    print(f"View Status | bash={ctl} param1='status' terminal=true")
    print("---")
    print("Refresh | refresh=true")


if __name__ == "__main__":
    main()
