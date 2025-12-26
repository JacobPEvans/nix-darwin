# Nix Configuration Runbook

Step-by-step procedures for common configuration tasks.

## Table of Contents

- [Everyday Commands](#everyday-commands)
- [Shell Aliases](#shell-aliases)
- [Adding Packages](#adding-packages)
- [Updating Packages](#updating-packages)
  - [Secure Flake Update Workflow](#secure-flake-update-workflow)
- [Rollback & Recovery](#rollback--recovery)
- [Dock Configuration](#dock-configuration)
- [Dev Shells](#dev-shells)
- [Host Profiles](#host-profiles)

---

## Everyday Commands

```bash
# Rebuild after config changes (most common)
sudo darwin-rebuild switch --flake ~/.config/nix

# Search for a package
nix search nixpkgs <name>

# Rollback if something breaks
sudo darwin-rebuild --rollback

# List all generations
sudo darwin-rebuild --list-generations
```

---

## Shell Aliases

Configured shell aliases make common tasks faster. All aliases are defined in `modules/home-manager/zsh/aliases.nix`.

### Directory Listing

| Alias | Command | Purpose |
|-------|---------|---------|
| `ll` | `ls -ahlFG -D '%Y-%m-%d %H:%M:%S'` | Long listing with human-readable sizes |
| `ll@` | `ls -@ahlFG -D '%Y-%m-%d %H:%M:%S'` | Long listing with extended attributes (macOS) |
| `llt` | `ls -ahltFG -D '%Y-%m-%d %H:%M:%S'` | Long listing sorted by modification time |
| `lls` | `ls -ahlsFG -D '%Y-%m-%d %H:%M:%S'` | Long listing with file sizes |

**Extended Attributes**: The `ll@` alias displays macOS extended attributes (xattr), useful for viewing security contexts, quarantine flags, and other metadata:

```bash
# View extended attributes
ll@

# Example output:
# -rw-r--r--@ 1 user  staff  1024 2025-01-15 14:30:00 file.txt
#   com.apple.quarantine      57
#   com.apple.metadata:kMDItemWhereFroms      183
```

### Docker

| Alias | Command | Purpose |
|-------|---------|---------|
| `dps` | `docker ps -a` | List all containers |
| `dcu` | `docker compose up -d` | Start compose stack (detached) |
| `dcd` | `docker compose down` | Stop compose stack |

### Nix / Darwin

| Alias | Command | Purpose |
|-------|---------|---------|
| `d-r` | `sudo darwin-rebuild switch --flake .` | Rebuild system configuration |
| `nf-u` | `nix flake update` | Update flake.lock to latest versions |

### AWS

| Alias | Command | Purpose |
|-------|---------|---------|
| `av` | `aws-vault exec` | Execute command with AWS profile |
| `avl` | `aws-vault list` | List profiles in vault |
| `avd` | `aws-vault exec default --` | Execute with default profile |
| `ava` | `aws-vault add` | Add profile to vault |
| `avr` | `aws-vault remove` | Remove profile from vault |

### Other

| Alias | Command | Purpose |
|-------|---------|---------|
| `python` | `python3` | Use Python 3 by default |
| `tgz` | `tar --disable-copyfile --exclude='.DS_Store' -czf` | Create tar.gz (macOS-friendly) |

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
   cd ~/.config/nix
   git add .
   git commit -m "feat: add <package>"
   sudo darwin-rebuild switch --flake .
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
cd ~/.config/nix

# 1. Update flake.lock to latest nixpkgs
nix flake update

# 2. Commit the updated lock file (required for flakes)
git add flake.lock
git commit -m "chore: update flake inputs"

# 3. Rebuild with new versions
sudo darwin-rebuild switch --flake .
```

**Recommended frequency**: Weekly or when you notice outdated packages.

### Update Homebrew Packages

Homebrew auto-update is disabled for faster rebuilds. To get latest versions:

```bash
# 1. Update Homebrew's package index
brew update

# 2. Rebuild (will upgrade packages based on new index)
sudo darwin-rebuild switch --flake ~/.config/nix
```

### If Something Breaks After Update

```bash
cd ~/.config/nix

# Undo the flake.lock update
git revert HEAD

# Rebuild with old versions
sudo darwin-rebuild switch --flake .
```

### Secure Flake Update Workflow

For production or critical systems, follow this secure workflow before applying updates:

#### 1. Build (Dry-Run)

Preview what would change without actually building:

```bash
cd ~/.config/nix
nix flake update  # Update flake.lock
nix build .#darwinConfigurations.$(hostname).system --dry-run
```

This shows package changes and download sizes without committing storage.

#### 2. Diff Package Changes

Compare current system with the updated configuration. Choose your preferred diff tool:

##### Option A: Native Nix (always available)

```bash
# Build the new configuration first
nix build .#darwinConfigurations.$(hostname).system -o result

# Compare closures
nix store diff-closures /run/current-system ./result
```

##### Option B: nvd (if installed)

```bash
nvd diff /run/current-system ./result
```

Both tools show version changes, additions, and removals for every package.

#### 3. Audit Critical Packages

**Human review required** - do not automate this step.

Review changes to security-sensitive packages:

- System packages (nix, darwin-rebuild)
- Security tools (gpg, ssh, certificates)
- Development tools with network access
- Packages with privileged access

**Check versions and lifecycles:**

- Review package version changes from step 2
- Check [endoflife.date](https://endoflife.date/) for NixOS and critical packages
- Verify packages are within supported lifecycle dates
- Look for major version jumps that may require configuration changes

**Security advisory check:**

- Search for CVEs affecting packages with significant version changes
- Review GitHub Security Advisories for key packages
- Check nixpkgs issue tracker for known problems

#### 4. Switch with Confidence

Only proceed after completing human review:

```bash
# Commit the flake.lock update
git add flake.lock
git commit -m "chore: update flake inputs"

# Apply the update
sudo darwin-rebuild switch --flake .
```

#### 5. Rollback Procedures

If issues occur after switching:

**Immediate rollback:**

```bash
# Rollback to previous generation
sudo darwin-rebuild --rollback
```

**Revert flake.lock:**

```bash
cd ~/.config/nix
git revert HEAD
sudo darwin-rebuild switch --flake .
```

**Switch to specific generation:**

```bash
# List available generations
sudo darwin-rebuild --list-generations

# Activate specific generation
sudo /nix/var/nix/profiles/system-<N>-link/activate
```

**Note**: This workflow adds safety checks before updates. For development systems or low-risk updates,
the standard "update and rebuild" workflow in [Updating Packages](#updating-packages) is sufficient.

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
# Uses hostname to auto-detect configuration
sudo darwin-rebuild switch --flake ~/.config/nix
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
