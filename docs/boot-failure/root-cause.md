# Root Cause Explanation

## Why Boot Failures Happen

On macOS with Determinate Nix + nix-darwin, there are two sets of launchd services:

| Service Owner | Services | Boot Behavior |
|---------------|----------|---------------|
| **Determinate Nix** | `systems.determinate.nix-daemon`, `systems.determinate.nix-store` | **Works** - bootstrapped during Determinate Nix installation |
| **nix-darwin** | `org.nixos.activate-system`, `org.nixos.darwin-store` | **May fail** - requires explicit bootstrap |

The `org.nixos.activate-system` service is responsible for:

1. Creating `/run/current-system` symlink
2. Running activation scripts
3. Setting up `/etc/static/*` symlinks
4. Configuring shell environment variables

If this service doesn't run at boot, your entire Nix environment appears broken.

## Why nix-darwin Services Don't Auto-Load

**Upstream Issue**: [nix-darwin#1255](https://github.com/nix-darwin/nix-darwin/issues/1255)

On modern macOS (Ventura+), LaunchDaemons in `/Library/LaunchDaemons/` need to be explicitly
**bootstrapped** into launchd using `launchctl bootstrap system <plist>`. Simply placing a
plist file in the directory is not enough.

nix-darwin uses the deprecated `launchctl load` command, which doesn't persist reliably.

Determinate Nix's installer runs this bootstrap step. nix-darwin's activation may skip it
if:

1. The services were already registered (but got unloaded somehow)
2. Activation was interrupted before the launchctl step
3. macOS's launchd cache got corrupted

## The Chain of Failure

```text
Boot
  └─→ /nix/store mounted (Determinate Nix - works)
  └─→ org.nixos.activate-system should run (nix-darwin - FAILS)
        └─→ /run/current-system symlink NOT created
              └─→ Shell config can't find NIX_PROFILES
                    └─→ PATH is empty
                          └─→ All Nix commands "not found"
```

## Why Determinate Nix Works But nix-darwin Fails

Determinate Nix's installation process explicitly bootstraps its services using modern
`launchctl bootstrap` commands. These services use socket activation and are properly
registered with launchd.

nix-darwin assumes that writing a plist to `/Library/LaunchDaemons/` is sufficient, but
this assumption doesn't hold on modern macOS. The deprecated `launchctl load` command
may appear to work initially but doesn't create persistent registrations.
