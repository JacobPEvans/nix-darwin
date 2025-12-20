#!/usr/bin/env python3
"""SwiftBar Auto-Claude Status Plugin."""

import json
import subprocess
from datetime import datetime
from pathlib import Path

HOME = Path.home()
CONTROL_FILE = HOME / ".claude" / "auto-claude-control.json"
LOG_DIR = HOME / ".claude" / "logs"
CTL_SCRIPT = HOME / ".claude" / "scripts" / "auto-claude-ctl.sh"


def get_active_sessions() -> int:
    """Count running Claude sessions."""
    try:
        result = subprocess.run(
            ["pgrep", "-f", "claude.*--print"],
            capture_output=True,
            text=True,
        )
        return len(result.stdout.strip().split("\n")) if result.stdout.strip() else 0
    except Exception:
        return 0


def parse_iso_time(iso_str: str):
    """Parse ISO timestamp."""
    try:
        return datetime.fromisoformat(iso_str.replace("Z", "+00:00"))
    except Exception:
        return None


def get_status():
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
        now = datetime.now()
        if pause_time:
            # Handle timezone-aware vs naive comparison
            try:
                if pause_time.tzinfo:
                    now = now.astimezone()
                if now < pause_time:
                    return "⏸️", f"Paused until {pause_time.strftime('%H:%M')}", "orange"
            except Exception:
                pass

    skip_count = data.get("skip_count", 0)
    if skip_count > 0:
        return "⏭️", f"Skipping {skip_count} runs", "yellow"

    return "🤖", "Active", "green"


def get_recent_logs(limit: int = 5):
    """Return [(name, size, path), ...] for recent logs."""
    if not LOG_DIR.exists():
        return []

    logs = sorted(LOG_DIR.glob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)
    result = []
    for log in logs[:limit]:
        size = log.stat().st_size
        if size > 1_000_000:
            size_str = f"{size / 1_000_000:.1f}MB"
        elif size > 1000:
            size_str = f"{size / 1000:.1f}KB"
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
            print(f"  {name} ({size}) | bash='open -R \"{path}\"' terminal=false")
    else:
        print("  No logs found | color=gray")

    print("---")

    # Actions
    ctl = str(CTL_SCRIPT)
    print("Actions | size=12")
    print(f"  Resume | bash='{ctl}' param1='resume' terminal=true refresh=true")
    print(f"  Pause 1 hour | bash='{ctl}' param1='pause' param2='1' terminal=true refresh=true")
    print(f"  Pause 4 hours | bash='{ctl}' param1='pause' param2='4' terminal=true refresh=true")
    print(f"  Skip next run | bash='{ctl}' param1='skip' param2='1' terminal=true refresh=true")
    print("---")
    print(f"  Run Now... | bash='{ctl}' param1='run' terminal=true")
    print("---")
    print(f"Open Logs Folder | bash='open \"{LOG_DIR}\"' terminal=false")
    print(f"View Status | bash='{ctl}' param1='status' terminal=true")
    print("---")
    print("Refresh | refresh=true")


if __name__ == "__main__":
    main()
