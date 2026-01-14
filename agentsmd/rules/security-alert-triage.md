# Security Alert Triage

When code scanning alerts appear in GitHub, triage them according to this framework.

## Python Logging Alerts

Check if the flagged logging actually reveals secrets.

### FALSE POSITIVE (dismiss as "false positive")

- **Slack/Discord channel IDs**: Public workspace identifiers, not secrets
  - Example: Logging channel ID like `C1234567890`
- **Configuration metadata**: Key names, not values
  - Example: Logging `"keychain_key": "SLACK_CHANNEL_ID_nix-config"` (metadata about where the value came from)
- **Operational data**: Status strings, counts, ratios
  - Example: Logging `"status": "ok"` or `"issue_count": 42`

### WON'T FIX (dismiss as "won't fix" for credential helpers)

Scripts whose purpose is to output secrets for headless authentication:

- `bws_helper.py` - Retrieves secrets from Bitwarden for use in CI/CD
- `get-api-key.py` - Retrieves OAuth tokens for Claude authentication

These scripts are designed to output secrets because that's their function.
The output is piped directly to environment variables by callers, not logged.

### REQUIRES FIX

- Actual API keys, OAuth tokens, passwords being logged outside credential helpers
- Test-only files that unintentionally expose secrets
- Any logging that bypasses secure credential handling

## GitHub Actions Permissions Alerts

Always add explicit `permissions` blocks.

### Standard Permission

Most workflows only need to read repository contents:

```yaml
permissions:
  contents: read
```

Add this to workflows that:

- Check out code
- Read files from the repository
- Run linters, validators, or build steps
- Don't write to the repository

### Multiple Permissions

If a workflow needs more permissions, add them explicitly:

```yaml
permissions:
  contents: read
  pull-requests: read
```

Examples:

- Workflows that read PR metadata need `pull-requests: read`
- Workflows that write checks need `checks: write`
- Workflows that post comments need `pull-requests: write`

### Reusable Workflows

Reusable workflows (with `on: workflow_call`) inherit permissions from callers.
Still add explicit permissions to be defensive:

```yaml
on:
  workflow_call:

permissions:
  contents: read

jobs:
  ...
```

## Other Alerts

Refer to SECURITY.md for policy on alerts not covered here.
When in doubt, ask for guidance in the PR review.
