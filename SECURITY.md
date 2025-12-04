# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| main    | Yes       |
| Everything else | Best effort |

This is a Nix configuration repo. The attack surface is mostly "did someone commit something dumb." But if you find something, I want to know.

## Reporting a Vulnerability

**Please don't open a public issue for security vulnerabilities.**

Instead:

1. Email the maintainer directly (check the git log for contact info)
2. Or use GitHub's private vulnerability reporting feature

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fixes (if you have them)

## Response Timeline

I maintain this project in my spare time, so:

- **Acknowledgment**: Within a week, usually faster
- **Assessment**: Within two weeks
- **Fix**: Depends on severity and complexity

For critical issues (like accidentally committed secrets), I'll prioritize accordingly.

## What Counts as a Security Issue

- Secrets accidentally committed
- Nix expressions that could compromise systems
- Overly permissive AI CLI permissions that shouldn't be auto-approved
- Anything that could harm systems using this configuration

## What Probably Doesn't Count

- Nix evaluation warnings
- Broken links in documentation
- Typos (unless they cause dangerous behavior)

---

*Thanks for helping keep this project safe.*
