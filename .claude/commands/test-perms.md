---
title: "Test Permissions"
description: "Validate Claude Code permissions are configured and functional"
type: "command"
version: "1.0.0"
allowed-tools:
  - "Read(**)"
  - "Glob(**)"
  - "Grep(**)"
  - "Bash(jq:*)"
  - "Bash(check-jsonschema:*)"
  - "Bash(whoami:*)"
  - "Bash(date:*)"
  - "Bash(pwd:*)"
  - "Bash(hostname:*)"
  - "Bash(uname:*)"
  - "Bash(uptime:*)"
  - "Bash(which:*)"
  - "Bash(whereis:*)"
  - "Bash(echo:*)"
  - "Bash(printf:*)"
  - "Bash(true:*)"
  - "Bash(false:*)"
  - "Bash(test:*)"
  - "Bash(ls:*)"
  - "Bash(tree:*)"
  - "Bash(wc:*)"
  - "Bash(head:*)"
  - "Bash(tail:*)"
  - "Bash(cat:*)"
  - "Bash(git --version:*)"
  - "Bash(git status:*)"
  - "Bash(node --version:*)"
  - "Bash(python --version:*)"
  - "Bash(nix --version:*)"
think: false
---

## Permission Validation

Verify Claude Code settings and test that allowed commands run without prompts.

### Steps

1. **Check Settings File**: Read `~/.claude/settings.json`, verify valid JSON, confirm `permissions.allow` has 100+ entries

2. **Validate Schema**: Run `check-jsonschema` against `https://json.schemastore.org/claude-code-settings.json`

3. **Test Single Command**: Run one command from this file's allowed-tools list

4. **Test Batch**: Run 5 more commands from allowed-tools in parallel

5. **Report**: PASS if no permission prompts occurred, FAIL otherwise
