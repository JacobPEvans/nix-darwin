# GitHub Actions Workflow Templates

Templates for integrating Claude Code into CI/CD pipelines.

## Available Templates

### PR Review Workflow

**File**: `claude-review.yml.template`

Automated pull request review using Claude Code's multi-agent code review system.

**Features**:
- Comprehensive code analysis
- Security vulnerability detection
- Best practices validation
- Automated comment posting

**Setup**:
1. Copy template to `.github/workflows/claude-review.yml`
2. Add `ANTHROPIC_API_KEY` to repository secrets
3. Customize triggers and thresholds as needed

### Security Review Workflow

**File**: `claude-security.yml.template`

AI-powered security scanning for continuous security monitoring.

**Features**:
- Vulnerability pattern detection
- Security best practices validation
- SARIF report generation
- Scheduled daily scans

**Setup**:
1. Copy template to `.github/workflows/claude-security.yml`
2. Add `ANTHROPIC_API_KEY` to repository secrets
3. Enable security events permissions
4. Customize scan schedule as needed

## Important Notes

⚠️ **These are reference templates**

The workflows reference hypothetical GitHub Actions:
- `anthropics/claude-code-action@v1`
- `anthropics/claude-code-security-review@v1`

Check the actual repositories for implementation details:
- https://github.com/anthropics/claude-code-action
- https://github.com/anthropics/claude-code-security-review

You may need to:
- Install Claude Code CLI in a setup step
- Run commands directly instead of using actions
- Adapt the workflow structure based on actual implementation

## Customization

Both workflows can be customized:

**Triggers**:
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
```

**Severity Thresholds**:
```yaml
with:
  severity-threshold: medium  # low, medium, high, critical
```

**Comment Formatting**:
Modify the `github-script` steps to customize comment content.

## Documentation

For complete documentation on the Anthropic ecosystem integration, see:
- [docs/ANTHROPIC-ECOSYSTEM.md](../docs/ANTHROPIC-ECOSYSTEM.md)

## Related Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [SARIF Format](https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/sarif-support-for-code-scanning)
