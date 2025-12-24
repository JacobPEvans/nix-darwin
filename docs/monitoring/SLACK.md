# Slack Notifications

Real-time Slack notifications for Auto-Claude runs.

## Overview

Auto-Claude sends rich Slack notifications using Block Kit for:

- Run start/end
- Task progress
- Blocked tasks
- Skipped runs
- Cost and duration summaries

## Configuration

### Per-Repository Channels

Configure Slack channels per repository in `modules/home-manager/ai-cli/claude-config.nix`:

```nix
programs.claude.autoClaude.repositories = {
  ai-assistant-instructions = {
    path = "/path/to/repo";
    schedule.hours = lib.lists.genList (i: i * 2) 12;
    maxBudget = 25.0;
    slackChannel = "C0AXXXXXXXX";  # Get from BWS: slack-channel-ai-assistant-instructions
  };
  nix = {
    path = "${config.home.homeDirectory}/.config/nix";
    schedule.hours = lib.lists.genList (i: i * 2 + 1) 12;
    maxBudget = 25.0;
    slackChannel = "C0AXXXXXXXX";  # Get from BWS: slack-channel-nix
  };
};
```

### Getting Channel IDs

1. Open Slack desktop or web app
2. Right-click on the target channel
3. Select "View channel details"
4. Scroll down to find the Channel ID (starts with `C`)

## Secret Setup

### Bitwarden Secrets Manager

The Slack bot token is stored in Bitwarden Secrets Manager:

1. Log into Bitwarden Secrets Manager
2. Create a new secret:
   - **Name**: `auto-claude-slack-bot-token`
   - **Value**: Your Slack bot token (starts with `xoxb-`)
3. Note the secret ID for reference

### Custom Secret ID

To use a custom secret ID, set the environment variable:

```bash
export BWS_SLACK_SECRET_ID="your-custom-secret-id"
```

### Verifying Secret Access

```bash
# Should return your token details (not the actual token)
bws secret get auto-claude-slack-bot-token
```

## Required Slack App Scopes

Your Slack app needs these OAuth scopes:

| Scope | Purpose |
|-------|---------|
| `chat:write` | Post messages to channels |
| `chat:write.public` | Post to public channels without joining |

### App Setup

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Create or select your app
3. Navigate to OAuth & Permissions
4. Add the required scopes
5. Install/reinstall to workspace
6. Copy the Bot User OAuth Token

## Notification Types

### Run Started

Sent when auto-claude begins a run.

```text
🚀 Auto-Claude Run Started
Repository: nix-config
Budget: $25.00
Run ID: 20241220_140532
Time: 2024-12-20 14:05:32
```

This creates the parent message. All subsequent notifications are threaded under it.

### Task Started

Sent when a subagent is spawned.

```text
🔧 Task Started
Task: Fix CI failures
Agent Type: ci-fixer
Parent: orchestrator
```

### Task Completed

Sent when a task finishes successfully.

```text
✅ Task Completed
Task: Fix CI failures
PR: #123
Cost: $1.23
Duration: 5 min
```

### Task Blocked

Sent when a task fails or requires user input.

```text
⚠️ Task Blocked
Task: Implement feature
Reason: Requires user input for API design decision
```

### Run Completed

Sent when the full run finishes. Updates the parent message and posts summary.

```text
✅ Auto-Claude Run Completed
Repository: nix-config
Duration: 45 min
Total Cost: $12.50
Budget: $25.00 (50% used)
Tasks: 5 completed, 1 blocked
```

### Run Skipped

Sent when a run is skipped (e.g., due to pause control).

```text
⏭️ Auto-Claude Run Skipped
Repository: nix-config
Time: 2024-12-20 14:05:32
Reason: Paused until 2024-12-20 16:00:00
```

## Threading

All notifications for a single run are threaded under the initial "Run Started" message:

```text
🚀 Auto-Claude Run Started (parent message)
├── 🔧 Task Started: Fix CI
├── ✅ Task Completed: Fix CI
├── 🔧 Task Started: Update docs
├── ✅ Task Completed: Update docs
└── ✅ Run Completed (summary)
```

The parent message is updated when the run completes to show final status.

## Testing

### Manual Trigger

```bash
# Trigger a manual run
auto-claude-ctl run ai-assistant-instructions
```

### Direct Notification Test

```bash
# Test run_started
~/.claude/scripts/auto-claude-notify.py run_started \
  --repo test \
  --budget 1.0 \
  --run-id test-123 \
  --channel C0AXXXXXXXX

# Test run_skipped
~/.claude/scripts/auto-claude-notify.py run_skipped \
  --repo test \
  --reason "Testing skip notification" \
  --channel C0AXXXXXXXX
```

### Environment Check

```bash
# Verify bws authentication
bws secret list

# Check for errors in the notifier
~/.claude/scripts/auto-claude-notify.py run_started \
  --repo test --budget 1 --run-id test --channel TEST 2>&1
```

## Troubleshooting

### Secret Not Found

```text
Error: Could not find secret 'auto-claude-slack-bot-token'
```

Solution:

1. Verify the secret exists in Bitwarden Secrets Manager
2. Check `BWS_ACCESS_TOKEN` is set
3. Try `bws secret get auto-claude-slack-bot-token`

### Channel Not Found

```text
Error: channel_not_found
```

Solution:

1. Verify the channel ID is correct (starts with `C`)
2. Ensure the bot is added to the channel
3. For public channels, verify `chat:write.public` scope

### Rate Limiting

```text
Error: ratelimited
```

Solution:

1. Reduce notification frequency
2. Batch updates where possible
3. Use threading to group related notifications

### Token Invalid

```text
Error: invalid_auth
```

Solution:

1. Regenerate the bot token in Slack app settings
2. Update the secret in Bitwarden Secrets Manager
3. Verify the token starts with `xoxb-`

## Block Kit Customization

The notifier uses Slack Block Kit for rich formatting. Customize in `auto-claude-notify.py`:

```python
blocks = [
    {
        "type": "header",
        "text": {"type": "plain_text", "text": "🚀 Custom Header", "emoji": True},
    },
    {
        "type": "section",
        "fields": [
            {"type": "mrkdwn", "text": "*Field 1:*\nValue 1"},
            {"type": "mrkdwn", "text": "*Field 2:*\nValue 2"},
        ],
    },
    {
        "type": "context",
        "elements": [
            {"type": "mrkdwn", "text": "Footer context text"},
        ],
    },
]
```

## Related Documentation

- [Auto-Claude Testing](../../modules/home-manager/ai-cli/claude/TESTING.md)
- [Main Monitoring Overview](../MONITORING.md)
