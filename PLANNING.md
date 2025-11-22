# Project Status & Planning

## Repository Context

- **Purpose**: Declarative macOS system management for M4 Max MacBook Pro (128GB RAM)
- **Target**: Production-ready nix-darwin configuration with home-manager
- **Approach**: Clean slate, minimal initial setup, incremental enhancement
- **Tools**: nix-darwin 25.05, home-manager 25.05, Determinate Nix 2.31.2

### Key Files

- `flake.nix` - Main entry point defining darwinConfigurations.default
- `flake.lock` - Locked dependency versions for reproducibility
- `darwin/configuration.nix` - System-level macOS settings and packages
- `home/home.nix` - User environment (shell, aliases, dotfiles)
- `SETUP.md` - Comprehensive setup guide and troubleshooting
- `CHANGELOG.md` - Version history and completed changes
- `README.md` - Quick reference guide
- `CLAUDE.md` - AI agent instructions for modifying this configuration
- `PLANNING.md` - This file, tracking current status and roadmap

## Current System State (2025-11-22)

### ✅ Fully Operational

**Package Management**:
- ALL packages now managed via nix/nix-darwin (no imperative installs)
- Homebrew configured as fallback-only (currently empty)
- No duplicate packages between nix and homebrew

**System Packages** (darwin/configuration.nix):
- claude-code - AI coding assistant
- gemini-cli - Google Gemini CLI
- gh - GitHub CLI
- git - Version control
- gnupg - GPG encryption (keys preserved)
- nodejs_latest - Node.js runtime
- vim - Text editor

**User Packages** (home/home.nix):
- VS Code - Declarative settings management
- Complete zsh configuration (aliases, functions, logging)
- Claude Code permissions - 277+ auto-approved commands (declarative)

**Configuration Health**:
- ✅ All packages resolve to nix store paths
- ✅ PATH correctly prioritizes nix over homebrew
- ✅ GPG keys preserved and functional
- ✅ VS Code settings managed declaratively
- ✅ Claude Code permissions managed declaratively
- ✅ All documentation up to date

## Completed Work

### Phase 1: Initial Setup (2025-11-19)
- ✅ Created flake-based nix-darwin configuration
- ✅ Integrated home-manager
- ✅ Migrated complete zsh configuration
- ✅ Resolved Determinate Nix compatibility (nix.enable = false)
- ✅ Created comprehensive documentation (SETUP.md)

### Phase 2: Package Management (2025-11-20)
- ✅ Added GitHub CLI (gh)
- ✅ Established documentation standards (CHANGELOG.md, README.md, PLANNING.md)

### Phase 3: Complete Package Migration (2025-11-21)
- ✅ Added all essential CLI tools via nix (claude, gemini, gpg, node)
- ✅ Added VS Code via home-manager
- ✅ Removed all homebrew package duplicates
- ✅ Resolved PATH priority issues
- ✅ Fixed GPG permissions and preserved keys
- ✅ Fixed VS Code userSettings deprecation
- ✅ Enhanced documentation with troubleshooting guides

### Phase 4: Declarative Configuration Management (2025-11-22)
- ✅ Implemented layered Claude Code permission management
- ✅ Created home/claude-permissions.nix with 277+ categorized commands
- ✅ Configured Nix-managed settings.json with user-writable settings.local.json
- ✅ Organized commands into 24 categories with security deny list
- ✅ Documented configuration strategy in CLAUDE.md
- ✅ Updated all documentation files for accuracy

## Near-Term Enhancements (Next 1-2 Months)

### 1. Profile Development

**Goal**: Implement multiple system profiles for different use cases

**Profiles to Create**:

1. **work**: Professional development environment
   - Communication apps (Slack, Zoom)
   - Productivity tools
   - Lighter weight than dev profile

2. **dev**: Full development environment
   - Language runtimes (Python, Go, Rust)
   - Development tools and IDEs
   - Database clients
   - Container tools (Docker, Colima)

3. **ai-research**: Machine learning and AI development
   - Ollama and model management
   - Python ML libraries
   - Jupyter and data science tools
   - Separate APFS volume for models (optional)

4. **minimal**: Bare essentials only
   - Shell tools only
   - For clean environment testing
   - Quick switching for troubleshooting

**Implementation**:
```nix
darwinConfigurations = {
  default = ...;
  work = ...;
  dev = ...;
  ai-research = ...;
  minimal = ...;
};
```

**Switching Profiles**:
```bash
darwin-rebuild switch --flake ~/.config/nix#work
darwin-rebuild switch --flake ~/.config/nix#dev
```

### 2. Essential Application Installation

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

### 3. macOS System Preferences

**Goal**: Declaratively manage macOS system settings

**Priority Settings**:
- Dock preferences (size, auto-hide, position)
- Finder settings (show hidden files, default view)
- Trackpad and mouse settings
- Keyboard shortcuts

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

### Immediate (Completed ✅)
- ✅ Minimal nix-darwin setup working
- ✅ Home-manager integrated and functional
- ✅ All shell configuration migrated
- ✅ Comprehensive documentation created
- ✅ All essential packages installed via nix
- ✅ No duplicate packages (homebrew cleaned up)
- ✅ PATH priority correct (nix before homebrew)

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
   - Resolution: Implement additional profiles (planned)

3. **GPG Warning Persists**: "unsafe ownership" warning still appears
   - Impact: None (GPG fully functional, keys work)
   - Resolution: May be false positive, not blocking functionality

4. **Empty Homebrew**: Homebrew configured but no packages
   - Impact: None (intended state - nix-first approach)
   - Status: Working as designed

## Maintenance Plan

### Weekly
- Review and update PLANNING.md with progress
- Commit any configuration tweaks
- Test system updates: `darwin-rebuild switch`

### Monthly
- Update flake dependencies: `nix flake update`
- Review and test new package versions
- Update CHANGELOG.md with notable changes
- Garbage collect old generations: `nix-collect-garbage -d`

### Quarterly
- Audit installed packages for unused items
- Review and optimize configuration
- Update documentation for accuracy
- Consider new features and enhancements

## Resources and References

- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [Home Manager manual](https://nix-community.github.io/home-manager/)
- [Determinate Nix](https://determinate.systems/nix-installer/)
- [nixpkgs search](https://search.nixos.org/packages)
- [Nix language basics](https://nix.dev/tutorials/nix-language)
