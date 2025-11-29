# Project Planning & Roadmap

**Future work and in-progress tasks only. For completed work, see [CHANGELOG.md](CHANGELOG.md).**

## Repository Context

- **Purpose**: Declarative macOS system management for M4 Max MacBook Pro (128GB RAM)
- **Target**: Production-ready nix-darwin configuration with home-manager
- **Approach**: Clean slate, minimal initial setup, incremental enhancement
- **Tools**: nix-darwin 25.05, home-manager 25.05, Determinate Nix 2.31.2

## Current Work: System Config Migration

**Branch**: `feat/system-config-migration`

### Phase 1: Fix Git/GPG Configuration ✅ COMPLETE
- [x] Add `programs.git` to home-manager
- [x] Enable GPG signing (`commit.gpgsign = true`)
- [x] Configure signing key in `user-config.nix`
- [x] Migrate to new `programs.git.settings` syntax
- [x] Extract git aliases to dedicated file (`git-aliases.nix`)
- [x] Extract shell aliases to dedicated file (`shell-aliases.nix`)
- [x] Document sudo requirements in TROUBLESHOOTING.md
- [x] Test signed commits (verified via PR)

### Phase 2: Application Migration ✅ COMPLETE
- [x] Migrate ripgrep to nixpkgs
- [x] Migrate raycast to nixpkgs (v1.103.2)
- [x] Migrate oh-my-zsh to `programs.zsh.oh-my-zsh`
- [x] Add zsh enhancements (autosuggestions, syntax highlighting, history)
- [x] Fix PR review comments (ll alias conflict, stash push, redundant home attr)

### Phase 3: macOS Customization Audit (NEXT)
- [ ] Review all System Preferences changes
- [ ] Audit backup/ directory for missed configs
- [ ] Add customizations to `system.defaults`

### Phase 4: Multi-Profile Architecture
- [ ] Create profile directory structure
- [ ] Implement common base profile
- [ ] Create default, development, work, minimal profiles
- [ ] Test profile switching

### Phase 5: Cleanup
- [ ] Verify all backup/ configs migrated
- [ ] Delete backup/ directory
- [ ] Update documentation

---

## Profile Architecture

**Goal**: Consistent profile names across all configuration levels

### Standard Profiles

| Profile | Purpose | Inherits From |
|---------|---------|---------------|
| **common** | Shared base configuration | - |
| **default** | Personal/everyday use | common |
| **development** | Extended dev tools, IDEs, debugging | common |
| **work** | Work-specific apps, VPNs, contexts | common |
| **minimal** | Bare essentials for troubleshooting | - |

### Profile Contents

1. **common** - Shared base (all profiles inherit except minimal)
   - Core CLI tools (git, vim, tree)
   - Shell configuration (zsh, aliases)
   - Basic system preferences
   - AI CLI configurations

2. **default** - Personal/everyday use
   - Personal applications
   - Media and entertainment
   - Personal git config (if different)

3. **development** - Full development environment
   - Language runtimes (Python, Go, Rust, Node)
   - Development tools and IDEs
   - Database clients
   - Container tools (Docker, Colima)
   - Debugging and profiling tools

4. **work** - Professional environment
   - Communication apps (Slack, Zoom)
   - Productivity tools
   - Work-specific VPN/network configs
   - Separate work contexts

5. **minimal** - Bare essentials
   - Shell only (zsh)
   - Core tools (git, vim)
   - For troubleshooting and recovery
   - Does NOT inherit from common

### Implementation Structure

```
~/.config/nix/
├── flake.nix                 # Defines all darwinConfigurations
├── profiles/
│   ├── common.nix            # Shared base
│   ├── default.nix           # Personal (imports common)
│   ├── development.nix       # Dev tools (imports common)
│   ├── work.nix              # Work env (imports common)
│   └── minimal.nix           # Standalone minimal
├── darwin/
│   └── configuration.nix     # System-level settings
└── home/
    ├── home.nix              # User-level settings
    └── profiles/             # Home-manager profile overrides
        ├── default.nix
        ├── development.nix
        ├── work.nix
        └── minimal.nix
```

### Switching Profiles

```bash
# Switch to different profiles
darwin-rebuild switch --flake ~/.config/nix#default
darwin-rebuild switch --flake ~/.config/nix#development
darwin-rebuild switch --flake ~/.config/nix#work
darwin-rebuild switch --flake ~/.config/nix#minimal
```

---

## Near-Term Goals (Next 1-2 Months)

### 1. Essential Application Installation

**Goal**: Install and configure essential applications via Nix

**Applications to Research**:
- Obsidian - Knowledge management
- Raycast - Productivity launcher
- Brave - Web browser
- Slack - Team communication

**Approach**:
1. Search for nix package availability
2. Add to appropriate profile (some may be profile-specific)
3. Configure declaratively where possible

### 2. macOS System Preferences

**Goal**: Declaratively manage macOS system settings (covered in Phase 3 above)

**Implementation Example**:
```nix
system.defaults = {
  dock = {
    autohide = true;
    tilesize = 48;
  };
  finder = {
    AppleShowAllExtensions = true;
  };
  NSGlobalDomain = {
    AppleKeyboardUIMode = 3;
  };
};
```

## Long-Term Vision (6-12 Months)

### 1. Multi-Machine Synchronization

**Goal**: Share configuration across multiple machines with machine-specific overrides

**Structure**:
```
~/.config/nix/
├── flake.nix
├── machines/
│   ├── macbook-m4-max/
│   │   └── configuration.nix
│   └── macbook-m2-air/
│       └── configuration.nix
├── shared/
│   ├── darwin-base.nix
│   └── home-base.nix
└── profiles/
    ├── work.nix
    ├── dev.nix
    └── minimal.nix
```

### 2. Advanced Features

- **Automated Backups**: Time Machine integration
- **Custom Services**: LaunchAgents for personal scripts
- **Development Reproducibility**: Per-project Nix shells with direnv

### 3. Pure Nix System

**Goal**: Completely declarative system with no imperative package management

**Status**: Foundation complete - all packages now via nix
**Next Steps**: Maintain discipline of always adding packages to config

## Success Criteria

### Short-Term (Next 1-2 Months)
- ⬜ At least 2 profiles implemented (default + work or dev)
- ⬜ Essential GUI applications installed via Nix
- ⬜ Basic macOS system preferences configured
- ⬜ Profile switching tested and documented

### Long-Term (6-12 Months)
- ⬜ All planned profiles implemented and tested
- ⬜ Multi-machine configuration support (if applicable)
- ⬜ Automated backup and recovery procedures
- ⬜ Pure Nix system maintained (no imperative installs)

## Known Limitations

### Non-Blocking Issues

1. **Nix Settings Warnings**: Harmless forward-compatibility warnings from Determinate Nix
   - Impact: None (warnings can be ignored)
   - Resolution: Will resolve when Nix version catches up

2. **Single Profile**: Only default profile exists
   - Impact: Cannot test profile switching yet
   - Resolution: Multi-profile architecture in progress (Phase 4)

3. **GPG Warning Persists**: "unsafe ownership" warning still appears
   - Impact: None (GPG fully functional, keys work)
   - Resolution: May be false positive, not blocking functionality

4. **Homebrew Exceptions**: Some packages via Homebrew cask
   - Impact: None (intentional for rapidly-evolving tools)
   - Status: claude-code via homebrew for auto-updates

## Maintenance Plan

### Weekly
- Review and update PLANNING.md with new tasks
- Commit any configuration tweaks
- Test system updates: `darwin-rebuild switch`

### Monthly
- Update flake dependencies: `nix flake update`
- Review and test new package versions
- Move completed work from PLANNING.md to CHANGELOG.md
- Garbage collect old generations: `nix-collect-garbage -d`

### Quarterly
- Audit installed packages for unused items
- Review and optimize configuration
- Update documentation for accuracy
- Consider new features and enhancements

## Resources

See [README.md](README.md) for documentation links and references.
