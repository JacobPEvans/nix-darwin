# Nix Configuration Runbook

Step-by-step procedures for common configuration tasks.

## Table of Contents

- [Everyday Commands](#everyday-commands)
- [Adding Packages](#adding-packages)
- [Updating Packages](#updating-packages)
- [Rollback & Recovery](#rollback--recovery)
- [Dock Configuration](#dock-configuration)
- [Dev Shells](#dev-shells)
- [Host Profiles](#host-profiles)

---

## Everyday Commands

```bash
# Rebuild after config changes (most common)
sudo darwin-rebuild switch --flake ~/.config/nix#default

# Search for a package
nix search nixpkgs <name>

# Rollback if something breaks
sudo darwin-rebuild --rollback

# List all generations
sudo darwin-rebuild --list-generations
```

---

## Adding Packages

### Adding a Nix Package (Preferred)

1. **Search nixpkgs first**:
   ```bash
   nix search nixpkgs <package>
   ```

2. **Add to system packages** in `modules/darwin/common.nix`:
   ```nix
   environment.systemPackages = with pkgs; [
     existing-package
     new-package  # Description of what it does
   ];
   ```

3. **Commit and rebuild**:
   ```bash
   git -C ~/.config/nix add .
   git -C ~/.config/nix commit -m "feat: add <package>"
   sudo darwin-rebuild switch --flake ~/.config/nix#default
   ```

### Adding a Homebrew Package (Fallback Only)

Only use Homebrew when:
- Package doesn't exist in nixpkgs
- Nixpkgs version is severely outdated
- Package requires Homebrew-specific integration

1. **Add to homebrew casks** in `modules/darwin/common.nix`:
   ```nix
   homebrew.casks = [
     "package-name"  # Why: not in nixpkgs
   ];
   ```

2. **Document the reason** in a comment

3. **Commit and rebuild**

### Adding a Mac App Store App

1. **Find the app ID**:
   ```bash
   mas search "<app name>"
   ```

2. **Add to mas apps** in `modules/darwin/common.nix`:
   ```nix
   homebrew.masApps = {
     "App Name" = 123456789;
   };
   ```

3. **Commit and rebuild**

---

## Updating Packages

### Update All Nix Packages

Nix flakes pin exact versions. To get newer versions:

```bash
# 1. Update flake.lock to latest nixpkgs
nix flake update ~/.config/nix

# 2. Commit the updated lock file (required for flakes)
git -C ~/.config/nix add flake.lock
git -C ~/.config/nix commit -m "chore: update flake inputs"

# 3. Rebuild with new versions
sudo darwin-rebuild switch --flake ~/.config/nix#default
```

**Recommended frequency**: Weekly or when you notice outdated packages.

### Update Homebrew Packages

Homebrew auto-update is disabled for faster rebuilds. To get latest versions:

```bash
# 1. Update Homebrew's package index
brew update

# 2. Rebuild (will upgrade packages based on new index)
sudo darwin-rebuild switch --flake ~/.config/nix#default
```

### If Something Breaks After Update

```bash
# Undo the flake.lock update
git -C ~/.config/nix revert HEAD

# Rebuild with old versions
sudo darwin-rebuild switch --flake ~/.config/nix#default
```

---

## Rollback & Recovery

### Quick Rollback

```bash
# Rollback to previous generation
sudo darwin-rebuild --rollback
```

### Switch to Specific Generation

```bash
# List available generations
sudo darwin-rebuild --list-generations

# Activate specific generation
sudo /nix/var/nix/profiles/system-<N>-link/activate
```

### Emergency Recovery

If the system is broken and normal commands fail:

```bash
# Boot into recovery mode or use another terminal
# Activate a known-good generation directly
sudo /nix/var/nix/profiles/system-1-link/activate
```

---

## Dock Configuration

### Change Dock App Order

1. **Edit** `modules/darwin/dock/persistent-apps.nix`

2. **Reorder apps** in the `persistent-apps` list (order = left to right)

3. **Commit and rebuild**

### Add an App to the Dock

1. **Find the app path**:
   ```bash
   # System apps
   ls /System/Applications/

   # Nix-managed apps
   ls "/Applications/Nix Apps/"

   # Manual installs
   ls /Applications/

   # User apps
   ls ~/Applications/
   ```

2. **Add to** `modules/darwin/dock/persistent-apps.nix`:
   ```nix
   persistent-apps = [
     # ... existing apps ...
     "/Applications/NewApp.app"
   ];
   ```

3. **Commit and rebuild**

### Add Items to Right Side of Dock (After Separator)

Use `persistent-others` for folders, stacks, or utility apps:

```nix
persistent-others = [
  "${homeDir}/Downloads"  # homeDir from user-config.nix
  "/System/Applications/System Settings.app"
];
```

### Dock Settings Reference

All dock behavior settings are in `modules/darwin/dock/default.nix`:
- Icon size, magnification
- Autohide behavior
- Hot corners
- Mission Control settings

---

## Dev Shells

### Using a Dev Shell

```bash
# Enter a development environment
nix develop ~/.config/nix#python
nix develop ~/.config/nix#python-data
nix develop ~/.config/nix#js
nix develop ~/.config/nix#go
nix develop ~/.config/nix#terraform
```

### Creating a New Dev Shell

1. **Create shell directory**: `shells/<name>/`

2. **Create flake.nix**:
   ```nix
   {
     description = "Shell description";

     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
       flake-utils.url = "github:numtide/flake-utils";
     };

     outputs = { self, nixpkgs, flake-utils }:
       flake-utils.lib.eachDefaultSystem (system:
         let pkgs = nixpkgs.legacyPackages.${system};
         in {
           devShells.default = pkgs.mkShell {
             packages = with pkgs; [
               # Add packages here
             ];
           };
         }
       );
   }
   ```

3. **Add to main flake.nix** in the `devShells` section

### Modifying an Existing Dev Shell

1. **Edit** `shells/<name>/flake.nix`

2. **Test the shell**:
   ```bash
   nix develop ~/.config/nix#<name>
   ```

No rebuild required - dev shells are evaluated on-demand.

---

## Host Profiles

### Switch to a Different Host Profile

```bash
# The default profile is macbook-m4
sudo darwin-rebuild switch --flake ~/.config/nix#default

# Or specify explicitly
sudo darwin-rebuild switch --flake ~/.config/nix#macbook-m4
```

### Creating a New Host Profile

1. **Create host directory**: `hosts/<hostname>/`

2. **Create default.nix** (system config):
   ```nix
   { ... }:
   {
     imports = [
       ../../modules/darwin/common.nix
     ];

     # Host-specific overrides here
   }
   ```

3. **Create home.nix** (user config):
   ```nix
   { ... }:
   {
     imports = [
       ../../modules/home-manager/common.nix
     ];

     # Host-specific user settings
   }
   ```

4. **Add to flake.nix** in `darwinConfigurations`

### Modifying Host-Specific Settings

- **System settings**: `hosts/<hostname>/default.nix`
- **User settings**: `hosts/<hostname>/home.nix`
- **Shared settings**: `modules/darwin/common.nix` or `modules/home-manager/common.nix`

---

## AI CLI Permissions

### Add a Command to Claude Code Allow List

1. **Edit** `modules/home-manager/permissions/claude-permissions-allow.nix`

2. **Add command** to appropriate category:
   ```nix
   gitCommands = [
     "Bash(git status:*)"
     "Bash(git new-command:*)"  # Add new command
   ];
   ```

3. **Commit and rebuild**

### Quick Permission Approval

For one-off approvals without editing Nix:
- Click "Accept indefinitely" in Claude UI
- Saves to `~/.claude/settings.local.json` (not Nix-managed)

### Permission Files Reference

| Tool | Allow List | Deny List |
|------|------------|-----------|
| Claude | `claude-permissions-allow.nix` | `claude-permissions-deny.nix` |
| Gemini | `gemini-permissions-allow.nix` | `gemini-permissions-deny.nix` |
| Copilot | `copilot-permissions-allow.nix` | `copilot-permissions-deny.nix` |
