#!/usr/bin/env python3
"""
Auto-Claude Slack Notifier

Rich Slack notifications for auto-claude runs using Block Kit formatting.
Supports threading for organized per-run notifications.

Usage:
    auto-claude-notify.py run_started --repo NAME --budget AMOUNT --run-id ID --channel CHANNEL_ID
    auto-claude-notify.py task_started --repo NAME --thread-ts TS --task DESC --agent TYPE
    auto-claude-notify.py task_completed --repo NAME --thread-ts TS --task DESC [--pr PR] [--cost COST] [--duration MIN]
    auto-claude-notify.py task_blocked --repo NAME --thread-ts TS --task DESC --reason REASON
    auto-claude-notify.py run_completed --repo NAME --thread-ts TS --log-file PATH --budget AMOUNT

Secrets:
    Slack bot token retrieved from Bitwarden Secrets Manager (bws).
    Set BWS_SECRET_ID env var or use default: auto-claude-slack-bot-token
"""

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional


def get_slack_token() -> str:
    """Retrieve Slack bot token from Bitwarden Secrets Manager."""
    secret_id = os.environ.get("BWS_SLACK_SECRET_ID", "auto-claude-slack-bot-token")

    try:
        result = subprocess.run(
            ["bws", "secret", "get", secret_id],
            capture_output=True,
            text=True,
            check=True,
        )
        secret_data = json.loads(result.stdout)
        return secret_data["value"]
    except subprocess.CalledProcessError as e:
        print(f"Error retrieving secret from bws: {e.stderr}", file=sys.stderr)
        sys.exit(1)
    except (json.JSONDecodeError, KeyError) as e:
        print(f"Error parsing bws response: {e}", file=sys.stderr)
        sys.exit(1)


def post_message(token: str, channel: str, blocks: list, text: str, thread_ts: Optional[str] = None) -> Optional[str]:
    """Post a message to Slack and return the message ts."""
    try:
        from slack_sdk import WebClient
        from slack_sdk.errors import SlackApiError

        client = WebClient(token=token)

        kwargs = {
            "channel": channel,
            "blocks": blocks,
            "text": text,  # Fallback for notifications
        }
        if thread_ts:
            kwargs["thread_ts"] = thread_ts

        response = client.chat_postMessage(**kwargs)
        return response["ts"]

    except SlackApiError as e:
        print(f"Slack API error: {e.response['error']}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Error posting to Slack: {e}", file=sys.stderr)
        return None


def update_message(token: str, channel: str, ts: str, blocks: list, text: str) -> bool:
    """Update an existing Slack message."""
    try:
        from slack_sdk import WebClient
        from slack_sdk.errors import SlackApiError

        client = WebClient(token=token)
        client.chat_update(channel=channel, ts=ts, blocks=blocks, text=text)
        return True

    except SlackApiError as e:
        print(f"Slack API error: {e.response['error']}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"Error updating Slack message: {e}", file=sys.stderr)
        return False


# =============================================================================
# Block Kit Templates
# =============================================================================


def blocks_run_started(repo: str, budget: float, run_id: str) -> tuple[list, str]:
    """Block Kit for run started notification."""
    now = datetime.now().strftime("%b %d, %I:%M %p")
    text = f"Auto-Claude run started: {repo}"

    blocks = [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": "🤖 Auto-Claude Run Started", "emoji": True},
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"*Repository*\n{repo}"},
                {"type": "mrkdwn", "text": f"*Budget*\n${budget:.2f}"},
                {"type": "mrkdwn", "text": f"*Started*\n{now}"},
                {"type": "mrkdwn", "text": f"*Run ID*\n`{run_id}`"},
            ],
        },
        {"type": "divider"},
        {
            "type": "context",
            "elements": [{"type": "mrkdwn", "text": "Task updates will appear in this thread..."}],
        },
    ]

    return blocks, text


def blocks_task_started(task: str, agent: str) -> tuple[list, str]:
    """Block Kit for task started notification."""
    text = f"Task started: {task}"

    blocks = [
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"🔧 *Dispatched*: {agent}"},
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"```{task}```"},
        },
    ]

    return blocks, text


def blocks_task_completed(task: str, pr: Optional[str], cost: Optional[float], duration: Optional[int]) -> tuple[list, str]:
    """Block Kit for task completed notification."""
    text = f"Task completed: {task}"

    fields = []
    if pr:
        fields.append({"type": "mrkdwn", "text": f"*PR Created*\n{pr}"})
    if cost is not None:
        fields.append({"type": "mrkdwn", "text": f"*Cost*\n${cost:.2f}"})
    if duration is not None:
        fields.append({"type": "mrkdwn", "text": f"*Duration*\n{duration} min"})

    blocks = [
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"✅ *Completed*: {task}"},
        },
    ]

    if fields:
        blocks.append({"type": "section", "fields": fields})

    return blocks, text


def blocks_task_blocked(task: str, reason: str) -> tuple[list, str]:
    """Block Kit for task blocked notification."""
    text = f"Task blocked: {task}"

    blocks = [
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"⚠️ *Blocked*: {task}"},
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"_Reason: {reason}_"},
        },
    ]

    return blocks, text


def blocks_run_completed(
    repo: str,
    duration_minutes: int,
    cost: float,
    budget: float,
    completed: list[str],
    blocked: list[dict],
    prs: list[str],
) -> tuple[list, str]:
    """Block Kit for run completed notification."""
    pct = (cost / budget * 100) if budget > 0 else 0
    text = f"Auto-Claude run completed: {repo}"

    blocks = [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": "📊 Auto-Claude Run Complete", "emoji": True},
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"*Duration*\n{duration_minutes} minutes"},
                {"type": "mrkdwn", "text": f"*Cost*\n${cost:.2f} / ${budget:.2f} ({pct:.0f}%)"},
                {"type": "mrkdwn", "text": f"*Tasks*\n{len(completed)} completed, {len(blocked)} blocked"},
            ],
        },
        {"type": "divider"},
    ]

    # Completed tasks
    if completed:
        completed_text = "\n".join(f"• {t}" for t in completed[:10])  # Limit to 10
        if len(completed) > 10:
            completed_text += f"\n_...and {len(completed) - 10} more_"
        blocks.append(
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*✅ Completed*\n{completed_text}"},
            }
        )

    # PRs created
    if prs:
        prs_text = "\n".join(f"• {pr}" for pr in prs[:10])
        blocks.append(
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*📝 PRs Created*\n{prs_text}"},
            }
        )

    # Blocked tasks
    if blocked:
        blocked_text = "\n".join(f"• {b.get('task', 'Unknown')}: _{b.get('reason', 'No reason')}_" for b in blocked[:5])
        blocks.append(
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*⚠️ Blocked*\n{blocked_text}"},
            }
        )

    return blocks, text


def parse_log_file(log_path: str) -> dict:
    """Parse JSONL log file for task events and summary data."""
    completed = []
    blocked = []
    prs = []
    total_cost = 0.0
    start_time = None
    end_time = None

    try:
        with open(log_path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    data = json.loads(line)

                    # Track timestamps for duration
                    if "timestamp" in data:
                        ts = data["timestamp"]
                        if start_time is None:
                            start_time = ts
                        end_time = ts

                    event = data.get("event")
                    if event == "task_completed":
                        completed.append(data.get("task", "Unknown task"))
                        if data.get("pr"):
                            prs.append(data["pr"])
                        if data.get("cost"):
                            total_cost += float(data["cost"])

                    elif event == "task_blocked":
                        blocked.append(
                            {
                                "task": data.get("task", "Unknown"),
                                "reason": data.get("reason", "No reason given"),
                            }
                        )

                except json.JSONDecodeError:
                    continue

    except FileNotFoundError:
        print(f"Warning: Log file not found: {log_path}", file=sys.stderr)

    # Calculate duration
    duration_minutes = 0
    if start_time and end_time:
        try:
            start = datetime.fromisoformat(start_time.replace("Z", "+00:00"))
            end = datetime.fromisoformat(end_time.replace("Z", "+00:00"))
            duration_minutes = int((end - start).total_seconds() / 60)
        except (ValueError, TypeError):
            pass

    return {
        "completed": completed,
        "blocked": blocked,
        "prs": prs,
        "total_cost": total_cost,
        "duration_minutes": duration_minutes,
    }


# =============================================================================
# CLI Commands
# =============================================================================


def cmd_run_started(args):
    """Handle run_started event."""
    token = get_slack_token()
    blocks, text = blocks_run_started(args.repo, args.budget, args.run_id)
    ts = post_message(token, args.channel, blocks, text)
    if ts:
        print(ts)  # Output ts for shell script to capture
        return 0
    return 1


def cmd_task_started(args):
    """Handle task_started event."""
    token = get_slack_token()
    blocks, text = blocks_task_started(args.task, args.agent)
    result = post_message(token, args.channel, blocks, text, thread_ts=args.thread_ts)
    return 0 if result else 1


def cmd_task_completed(args):
    """Handle task_completed event."""
    token = get_slack_token()
    blocks, text = blocks_task_completed(args.task, args.pr, args.cost, args.duration)
    result = post_message(token, args.channel, blocks, text, thread_ts=args.thread_ts)
    return 0 if result else 1


def cmd_task_blocked(args):
    """Handle task_blocked event."""
    token = get_slack_token()
    blocks, text = blocks_task_blocked(args.task, args.reason)
    result = post_message(token, args.channel, blocks, text, thread_ts=args.thread_ts)
    return 0 if result else 1


def cmd_run_completed(args):
    """Handle run_completed event."""
    token = get_slack_token()

    # Parse log file for summary data
    log_data = parse_log_file(args.log_file) if args.log_file else {}

    blocks, text = blocks_run_completed(
        repo=args.repo,
        duration_minutes=log_data.get("duration_minutes", 0),
        cost=log_data.get("total_cost", 0.0),
        budget=args.budget,
        completed=log_data.get("completed", []),
        blocked=log_data.get("blocked", []),
        prs=log_data.get("prs", []),
    )

    # Post summary as thread reply
    post_message(token, args.channel, blocks, text, thread_ts=args.thread_ts)

    # Update parent message with completion status
    parent_blocks, parent_text = blocks_run_started(args.repo, args.budget, args.run_id or "unknown")
    # Modify header to show completed
    parent_blocks[0]["text"]["text"] = "✅ Auto-Claude Run Completed"
    update_message(token, args.channel, args.thread_ts, parent_blocks, parent_text)

    return 0


def main():
    parser = argparse.ArgumentParser(description="Auto-Claude Slack Notifier")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # run_started
    p_start = subparsers.add_parser("run_started", help="Notify run started")
    p_start.add_argument("--repo", required=True, help="Repository name")
    p_start.add_argument("--budget", type=float, required=True, help="Budget in USD")
    p_start.add_argument("--run-id", required=True, help="Run ID")
    p_start.add_argument("--channel", required=True, help="Slack channel ID")
    p_start.set_defaults(func=cmd_run_started)

    # task_started
    p_task_start = subparsers.add_parser("task_started", help="Notify task started")
    p_task_start.add_argument("--repo", required=True)
    p_task_start.add_argument("--channel", required=True)
    p_task_start.add_argument("--thread-ts", required=True, help="Parent message ts")
    p_task_start.add_argument("--task", required=True, help="Task description")
    p_task_start.add_argument("--agent", required=True, help="Agent type")
    p_task_start.set_defaults(func=cmd_task_started)

    # task_completed
    p_task_done = subparsers.add_parser("task_completed", help="Notify task completed")
    p_task_done.add_argument("--repo", required=True)
    p_task_done.add_argument("--channel", required=True)
    p_task_done.add_argument("--thread-ts", required=True)
    p_task_done.add_argument("--task", required=True)
    p_task_done.add_argument("--pr", help="PR number/link if created")
    p_task_done.add_argument("--cost", type=float, help="Cost in USD")
    p_task_done.add_argument("--duration", type=int, help="Duration in minutes")
    p_task_done.set_defaults(func=cmd_task_completed)

    # task_blocked
    p_blocked = subparsers.add_parser("task_blocked", help="Notify task blocked")
    p_blocked.add_argument("--repo", required=True)
    p_blocked.add_argument("--channel", required=True)
    p_blocked.add_argument("--thread-ts", required=True)
    p_blocked.add_argument("--task", required=True)
    p_blocked.add_argument("--reason", required=True, help="Block reason")
    p_blocked.set_defaults(func=cmd_task_blocked)

    # run_completed
    p_complete = subparsers.add_parser("run_completed", help="Notify run completed")
    p_complete.add_argument("--repo", required=True)
    p_complete.add_argument("--channel", required=True)
    p_complete.add_argument("--thread-ts", required=True)
    p_complete.add_argument("--budget", type=float, required=True)
    p_complete.add_argument("--run-id", help="Run ID for parent update")
    p_complete.add_argument("--log-file", help="Path to JSONL log file")
    p_complete.set_defaults(func=cmd_run_completed)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
