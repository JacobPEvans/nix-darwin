# Auto-Claude Testing Documentation

Testing procedures for the auto-claude.sh autonomous maintenance script.

## Prerequisites

- zsh shell available
- Claude CLI installed (`claude` command in PATH)
- jq installed for JSON processing
- gh CLI installed for GitHub operations (optional but recommended)
- Deployed scripts via home-manager (`darwin-rebuild switch`)

## Basic Validation Tests

### 1. Syntax Validation

Verify the script has valid zsh syntax:

```bash
zsh -n modules/home-manager/ai-cli/claude/auto-claude.sh && echo "Syntax OK"
```

Expected: `Syntax OK`

### 2. Usage Message

Run without arguments to verify usage message:

```bash
zsh modules/home-manager/ai-cli/claude/auto-claude.sh
```

Expected output:

```text
Usage: /path/to/auto-claude.sh <target_dir> <max_budget_usd> [log_dir]
```

Exit code: 1

### 3. Invalid Directory Error

Test directory validation:

```bash
zsh modules/home-manager/ai-cli/claude/auto-claude.sh /nonexistent 10
```

Expected output:

```text
Error: Directory /nonexistent does not exist.
```

Exit code: 1

### 4. Invalid Budget Error (Negative)

Test budget validation with negative number:

```bash
zsh modules/home-manager/ai-cli/claude/auto-claude.sh /tmp -5
```

Expected output:

```text
Error: MAX_BUDGET_USD must be a positive number, got: -5
```

Exit code: 1

### 5. Decimal Budget Validation

Test that decimal budgets are accepted:

```bash
zsh modules/home-manager/ai-cli/claude/auto-claude.sh /tmp 0.5 2>&1 | head -5
```

Expected: Script starts executing (shows Claude initialization output)

## Deployed Script Tests

After `darwin-rebuild switch`, verify deployment:

### 1. Script Deployment

```bash
ls -la ~/.claude/scripts/auto-claude.sh ~/.claude/scripts/orchestrator-prompt.txt
```

Expected: Both files exist as symlinks to nix store paths

### 2. Executable Permissions

```bash
test -x ~/.claude/scripts/auto-claude.sh && echo "Executable OK"
```

Expected: `Executable OK`

### 3. LaunchAgent Registration

```bash
launchctl list | grep com.claude.auto-claude
```

Expected: One or more auto-claude agents listed (if autoClaude.enable = true)

## Integration Test (Live Run)

To test a live run with minimal budget:

```bash
~/.claude/scripts/auto-claude.sh ~/git/test-repo 0.10 /tmp/auto-claude-test
```

This will:

1. Source shell configs for environment
2. Load orchestrator prompt
3. Start Claude with the specified budget
4. Log output to /tmp/auto-claude-test/

### Verify Log Output

```bash
ls -la /tmp/auto-claude-test/
cat /tmp/auto-claude-test/summary.log
```

## Slack Notification Tests

If Slack webhook is configured:

### 1. Check Secrets File

```bash
test -r ~/.config/secrets/slack-webhook && echo "Secrets file exists"
```

### 2. Test Startup Notification

The script sends `{"text":"Auto-Claude run started"}` on startup.

### 3. Test Completion Notification

On completion, sends either:

- Rich Block Kit message (if structured summary found)
- Simple text message: `Auto-Claude <status>: <repo> [run: <id>] (exit <code>)`

## Troubleshooting

### Script Not Found

If `claude` command not found after launchd execution:

1. Check PATH in launchd agent:

   ```bash
   cat ~/Library/LaunchAgents/com.claude.auto-claude-*.plist | grep -A5 PATH
   ```

2. Verify PATH includes `/run/current-system/sw/bin`

### Orchestrator Prompt Missing

If prompt file not found:

```bash
ls -la ~/.claude/scripts/orchestrator-prompt.txt
```

If missing, run `darwin-rebuild switch` to deploy.

### API Authentication Failures

If headless auth fails:

1. Verify apiKeyHelper is enabled
2. Check BWS secret access:

   ```bash
   ~/.local/bin/claude-api-key-helper
   ```

3. Verify keychain token:

   ```bash
   security find-generic-password -s bws-claude-automation -w
   ```
