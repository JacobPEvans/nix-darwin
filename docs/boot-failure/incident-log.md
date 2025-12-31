# Boot Failure Incident Log

Historical log of boot failure incidents and their resolutions.

## 2025-12-31: Full Environment Failure After Restart

**Symptoms**:

- PATH completely empty after system restart
- `darwin-rebuild: command not found`
- `/run/current-system` did not exist
- All nix-darwin LaunchDaemons (`org.nixos.*`) were not loaded

**Root Cause**:

nix-darwin's LaunchDaemon plists existed in `/Library/LaunchDaemons/` but were never
`launchctl bootstrap`ed into launchd. Determinate Nix's services (`systems.determinate.*`)
worked fine because they're bootstrapped during Determinate Nix installation.

This is a known upstream issue: [nix-darwin#1255](https://github.com/nix-darwin/nix-darwin/issues/1255)

**Resolution**:

1. Manually bootstrapped services: `sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.activate-system.plist`
2. Ran activation: `sudo /nix/var/nix/profiles/system/activate`
3. Started new shell: `exec zsh`

**Prevention**:

Created `modules/darwin/launchd-bootstrap.nix` to ensure services are always bootstrapped
during activation using the modern `launchctl bootstrap` API.

**PR**: [#423](https://github.com/JacobPEvans/nix/pull/423)

---

## Template for Future Incidents

### YYYY-MM-DD: Brief Description

**Symptoms**:

- List observable symptoms
- Include error messages
- Note what failed

**Root Cause**:

Explanation of why it happened.

**Resolution**:

1. Steps taken to resolve
2. Commands executed
3. Verification performed

**Prevention**:

Changes made to prevent recurrence.
