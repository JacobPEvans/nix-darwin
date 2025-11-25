# AI Agent Instructions for Nix Configuration

**Strict guidance for AI agents modifying this nix-darwin configuration.**

## Critical Requirements

### 1. Flakes-Only Configuration
- **NEVER use nix-channels or non-flake commands**
- All changes must be committed to git before rebuild
- Use: `darwin-rebuild switch --flake ~/.config/nix#default`

### 2. Determinate Nix Compatibility
- **NEVER enable nix-darwin's Nix management**
- `nix.enable = false` must remain in darwin/configuration.nix
- Determinate Nix manages the daemon and nix itself

### 3. Nixpkgs First, Auto-Updates Preferred
- **ALL packages from nixpkgs unless impossible**
- Homebrew is fallback ONLY for packages not in nixpkgs or requiring frequent updates
- Search first: `nix search nixpkgs <package>`
- **Favor auto-updates**: For rapidly-evolving tools, prefer Homebrew cask with autoupdate
- Document why homebrew was needed if used

**Auto-Update Strategy:**
- Homebrew `onActivation.upgrade = true` upgrades packages on darwin-rebuild
- `brew autoupdate` runs every 24 hours for background updates
- Nix packages update via `nix flake update` (manual, less frequent)

**Current Homebrew Exceptions:**
- `claude-code` - Rapidly-evolving developer tool (auto-updates every 24h)
  - Nixpkgs version lags behind releases
  - Can't auto-update from read-only nix store
  - Background updates via `brew autoupdate`
  - Manual: `brew upgrade --cask claude-code`

### 4. Code Style for Learning
- **Keep comments** - user is learning Nix
- Show empty sections with examples (even if commented out)
- Visibility > minimalism
- Use `_latest` variants (e.g., `nodejs_latest`)

## File Organization

```
~/.config/nix/
├── flake.nix                  # Entry point - darwinConfigurations.default
├── darwin/configuration.nix   # System packages, settings
├── home/
│   ├── home.nix              # User environment, Claude settings
│   ├── claude-permissions.nix # 277+ categorized auto-approved commands
│   └── zsh/                  # Modular shell configs
├── CLAUDE.md                 # This file - AI instructions
├── README.md                 # User quick reference
├── SETUP.md                  # Detailed troubleshooting
├── CHANGELOG.md              # Completed tasks only
└── PLANNING.md               # Future/in-progress tasks only
```

## Task Management Workflow

**STRICT PATTERN - Follow without exception:**

1. **Tasks come from user** - All tasks originate from user requests
2. **PLANNING.md for active work** - Not started or in-progress tasks ONLY
3. **CHANGELOG.md for completed work** - ALL completed tasks ONLY
4. **NO overlap** - A task must NEVER appear in both files
5. **Clean up regularly** - Reorganize PLANNING.md and clean CHANGELOG.md as needed

**When completing a task:**
1. Remove from PLANNING.md immediately
2. Add to CHANGELOG.md under appropriate date
3. Ensure no task exists in both files

**File purposes:**
- `PLANNING.md` = Future roadmap + current work in progress
- `CHANGELOG.md` = Historical record of completed work

## Common Mistakes to Avoid

### Duplicate Packages (Homebrew + Nix)
**Problem**: Adding package to nix but homebrew version still installed
**Check**: `which <package>` should show `/run/current-system/sw/bin/<package>`
**Fix**: `sudo -u jevans brew uninstall <package>`
**Verify**: Backup important configs first (GPG keys, app settings)

### PATH Priority
**Correct order**: Nix paths before homebrew
1. `/Users/jevans/.nix-profile/bin`
2. `/etc/profiles/per-user/jevans/bin`
3. `/run/current-system/sw/bin` ← nix packages
4. `/nix/var/nix/profiles/default/bin`
5. `/opt/homebrew/bin` ← fallback only

**If wrong**: Check `~/.zprofile` for manual homebrew PATH additions

### VS Code Deprecated API
**Use**: `programs.vscode.profiles.default.userSettings`
**NOT**: `programs.vscode.userSettings`

## Claude Code Permission Management

**Layered Strategy**: Nix manages baseline, settings.local.json for ad-hoc approvals

**Nix-managed** (`~/.claude/settings.json`):
- Defined in `home/claude-permissions.nix`
- 277+ commands in 24 categories
- Version controlled, reproducible
- Updated via darwin-rebuild

**User-managed** (`~/.claude/settings.local.json`):
- NOT managed by Nix (intentionally writable)
- Claude writes here on "accept indefinitely"
- Machine-local only

**To add commands permanently**:
1. Edit `home/claude-permissions.nix`
2. Add to appropriate category
3. Commit and rebuild

**For quick approval**: Just click "accept indefinitely" in Claude UI

## Workflow

1. Make changes to nix files
2. **Commit to git** (flakes requirement)
3. Test build: `nix build ~/.config/nix#darwinConfigurations.default.system`
4. Apply: `darwin-rebuild switch --flake ~/.config/nix#default`
5. Update CHANGELOG.md for significant changes
