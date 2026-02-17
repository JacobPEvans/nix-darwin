# LaunchAgent Naming & Login Items Best Practices

## Problem

macOS System Settings > General > Login Items shows background items.
Without proper naming, items display as "sh", "watchexec", or the signing
organization name instead of a human-readable identifier.

**"sh" in Login Items or background activity notifications is NEVER acceptable.**

## The home-manager /bin/sh Problem

home-manager's `launchd.agents` module (since PR #8609, Jan 2026) wraps ALL
`ProgramArguments` with `/bin/sh -c "/bin/wait4path /nix/store && exec ..."`.
This is intentional (waits for the Nix store APFS volume to mount at boot),
but macOS identifies processes by `ProgramArguments[0]` — so it shows "sh".

There is **no option to disable this**. The `mutateConfig` function in
`modules/launchd/default.nix` is applied unconditionally to every agent.

### Solution: Bypass launchd.agents

For agents that must display properly in Login Items, **bypass
home-manager's `launchd.agents`** and manage the plist directly:

1. Create a **named launcher script** via `pkgs.writeShellScript "service-name"`
2. Handle `/bin/wait4path /nix/store` in the launcher script
3. Generate the plist via `lib.generators.toPlist` with the launcher as
   `ProgramArguments[0]`
4. Install and manage lifecycle via `home.activation`

macOS displays the basename of `ProgramArguments[0]`, so a script named
`granola-watcher` shows "granola-watcher" instead of "sh".

See `modules/home-manager/ai-cli/claude/granola-watcher.nix` for the
reference implementation.

### What NOT To Do

- Do NOT use `launchd.agents` for user-visible background services
- Do NOT try to set `Program` to override — `mutateConfig` strips it
- Do NOT accept "sh" as "just cosmetic" — it violates naming policy

## Required Properties

Every Nix-managed LaunchAgent plist MUST include:

### 1. Label (reverse-DNS)

Use `com.visicore.{service-name}` for all VisiCore services:

| Service | Label |
| --- | --- |
| Granola Watcher | `com.visicore.granola-watcher` |

### 2. AssociatedBundleIdentifiers

Associates the background item with a visible app in System Settings.

Use Ghostty's bundle ID (our terminal app with Full Disk Access):

```text
AssociatedBundleIdentifiers = [ "com.mitchellh.ghostty" ];
```

This ensures:

- Login Items groups the agent under Ghostty
- The agent inherits Ghostty's TCC permissions (Full Disk Access)
- Users can identify and manage the agent in System Settings

### 3. Named ProgramArguments[0] (CRITICAL)

`ProgramArguments[0]` MUST be a descriptively-named executable, never
`/bin/sh` or `/bin/bash`. Use `pkgs.writeShellScript "service-name"` to
create a launcher with a meaningful basename.

## Naming Convention

| Component | Convention | Example |
| --- | --- | --- |
| Label | `com.visicore.{service}` | `com.visicore.granola-watcher` |
| Plist filename | matches Label | `com.visicore.granola-watcher.plist` |
| Launcher script | `pkgs.writeShellScript "{service}"` | basename: `granola-watcher` |
| Log files | `~/.claude/logs/{service}.log` | `~/.claude/logs/granola-watcher.log` |
| Lock files | `~/.claude/locks/{service}.lock` | `~/.claude/locks/granola-migrate.lock` |
| Scripts | `~/.claude/scripts/{service}.sh` | `~/.claude/scripts/granola-migrate.sh` |

## Activation Script Pattern

```nix
home.activation.manageMyService = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  PLIST_DST="$HOME/Library/LaunchAgents/com.visicore.my-service.plist"
  LABEL="com.visicore.my-service"

  # Only update if plist changed
  if ! cmp -s "${plistFile}" "$PLIST_DST" 2>/dev/null; then
    $DRY_RUN_CMD launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
    $DRY_RUN_CMD install -m 444 "${plistFile}" "$PLIST_DST"
    $DRY_RUN_CMD launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"
  fi
'';
```

## Audit Existing Agents

Check all agents display properly:

```bash
ls ~/Library/LaunchAgents/*.plist
# For each: verify ProgramArguments[0] is NOT /bin/sh
plutil -p ~/Library/LaunchAgents/com.visicore.*.plist | grep -A2 ProgramArguments
```

## References

- home-manager PR #8609: launchd wait4path wrapper (cause of /bin/sh)
- nix-darwin PR #1052: Similar wait4path approach
- Apple: AssociatedBundleIdentifiers groups items under the associated app
- KeePassXC PR #11373: Fix for ambiguous Login Items display
