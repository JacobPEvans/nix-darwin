# Root Cause Explanation

## Why Boot Failures Happen

There are **two separate issues** that can cause boot failures with Determinate Nix + nix-darwin:

### Issue 1: App Management Permission Check (Primary Cause)

**This is the main reason activation fails at boot.**

The nix-darwin activation script (`activate-system-start`) includes an App Management
permission check that **requires a graphical session (Aqua)** to succeed:

```bash
# From activate-system-start
if [[ "$(launchctl managername)" != Aqua ]]; then
    # Fails with exit code 1 - "permission denied over SSH"
fi
```

**At boot time:**

1. `org.nixos.activate-system` LaunchDaemon runs (confirmed by `launchctl print` showing `runs = 1`)
2. No graphical session exists yet - `launchctl managername` returns something other than "Aqua"
3. The App Management check fails → activation exits with code 1
4. `/run/current-system` symlink is never created

**Diagnostic command:**

```bash
launchctl print system/org.nixos.activate-system | grep "last exit code"
# If this shows "last exit code = 1", the script ran but failed
```

### Issue 2: LaunchDaemon Bootstrap (Secondary Cause)

**Upstream Issue**: [nix-darwin#1255](https://github.com/nix-darwin/nix-darwin/issues/1255)

On modern macOS (Ventura+), LaunchDaemons need explicit bootstrap via `launchctl bootstrap`.
nix-darwin uses deprecated `launchctl load` which doesn't persist reliably.

This is a **secondary issue** - even if the LaunchDaemon IS loaded, Issue 1 causes it to fail.

## Service Architecture

| Service Owner | Services | Boot Behavior |
|---------------|----------|---------------|
| **Determinate Nix** | `systems.determinate.nix-store` | ✅ Works - mounts `/nix` volume |
| **Determinate Nix** | `systems.determinate.nix-daemon` | ✅ Works - socket activation |
| **nix-darwin** | `org.nixos.darwin-store` | ⚠️ May need bootstrap |
| **nix-darwin** | `org.nixos.activate-system` | ❌ Runs but FAILS (exit code 1) |

The `org.nixos.activate-system` service is responsible for:

1. Creating `/run/current-system` symlink
2. Running activation scripts
3. Setting up `/etc/static/*` symlinks
4. Configuring shell environment variables

## The Chain of Failure

```text
Boot
  └─→ /nix volume mounted (Determinate Nix - works)
  └─→ org.nixos.activate-system runs (nix-darwin)
        └─→ App Management check: "launchctl managername" != "Aqua"
              └─→ Script exits with code 1 (no GUI session at boot)
                    └─→ /run/current-system symlink NOT created
                          └─→ Shell config can't find NIX_PROFILES
                                └─→ PATH is empty
                                      └─→ All Nix commands "not found"
```

## Why Manual Recovery Works

When you run `sudo /nix/var/nix/profiles/system/activate` from a terminal:

1. You're in a graphical session - `launchctl managername` returns "Aqua"
2. The App Management check passes
3. Activation completes successfully
4. `/run/current-system` is created

This is why the environment "fixes itself" after manual activation but breaks again on reboot.

## Why Determinate Nix Works But nix-darwin Fails

Determinate Nix services:

- Use socket activation (no permission checks needed)
- Are bootstrapped during installation
- Don't require GUI access

nix-darwin's activation:

- Requires App Management permission for `/Applications/Nix Apps/`
- This permission check requires a graphical session
- At boot time, no graphical session exists yet
